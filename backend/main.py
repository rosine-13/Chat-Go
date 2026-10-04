import os
import json
import sqlite3
import unicodedata
import re
from difflib import SequenceMatcher
from datetime import datetime
from typing import Optional
import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

load_dotenv()

app = FastAPI(title="Chat&Go - Backend")

# ============================================================
# CORS
# ============================================================

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ============================================================
# CONFIGURATION
# ============================================================

DEEPSEEK_API_KEY = os.environ.get("DEEPSEEK_API_KEY")
DEEPSEEK_URL = "https://api.deepseek.com/chat/completions"

SERPAPI_KEY = os.environ.get("SERPAPI_KEY")
SERPAPI_URL = "https://serpapi.com/search"

# ============================================================
# MODÈLES PYDANTIC
# ============================================================

class MessageEntrant(BaseModel):
    texte: str

class InscriptionRequest(BaseModel):
    first_name: str
    last_name: str
    email: str
    whatsapp: str
    password: str

class ConnexionRequest(BaseModel):
    email: str
    password: str

# ============================================================
# 🔥 VALIDATION DU NUMÉRO WHATSAPP (CÔTE D'IVOIRE)
# ============================================================

def valider_whatsapp(whatsapp: str) -> bool:
    """
    Valide un numéro WhatsApp ivoirien.
    Format attendu : +225 suivi de 10 chiffres.
    Exemples valides :
    - +2250100483141
    - +225 01 00 48 31 41
    """
    # Nettoyer le numéro (supprimer les espaces)
    whatsapp = whatsapp.strip()
    whatsapp = re.sub(r'\s', '', whatsapp)
    
    # Vérifier le format : +225 + 10 chiffres
    pattern = r'^\+225[0-9]{10}$'
    return re.match(pattern, whatsapp) is not None

# ============================================================
# INITIALISATION DE LA BASE DE DONNÉES
# ============================================================

def _initialiser_base():
    """Garantit que la base est prête au démarrage."""
    connexion = sqlite3.connect("chatgo.db")
    curseur = connexion.cursor()

    # TABLE DES PRESTATAIRES
    curseur.execute("""
    CREATE TABLE IF NOT EXISTS prestataires (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        categorie TEXT NOT NULL,
        mots_cles TEXT NOT NULL,
        ville TEXT NOT NULL,
        telephone TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        disponible INTEGER NOT NULL DEFAULT 1,
        photo_url TEXT
    )
    """)

    try:
        curseur.execute("ALTER TABLE prestataires ADD COLUMN photo_url TEXT")
    except sqlite3.OperationalError:
        pass

    # TABLE DES UTILISATEURS
    curseur.execute("""
    CREATE TABLE IF NOT EXISTS utilisateurs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        whatsapp TEXT NOT NULL,
        password TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        last_login DATETIME
    )
    """)

    # DONNÉES DE BASE (prestataires)
    curseur.execute("SELECT COUNT(*) FROM prestataires")
    nombre_actuel = curseur.fetchone()[0]

    if nombre_actuel == 0:
        prestataires_de_base = [
            ("AS DE LA PLOMBERIE", "depannage", "plomberie, plombier, fuite, eau, urgence", "Abidjan", "+2250707767555", 5.3080321, -4.0878349, 1, None),
            ("Electro Rapide CI", "depannage", "electricite, electricien, panne, courant, clim", "Cocody", "+2250700000002", 5.3450000, -4.0100000, 1, None),
            ("Texas GrillZ Yopougon", "restauration", "restaurant, grill, cuisine, maquis", "Yopougon", "+2250777450000", 5.3436561, -4.1002879, 1, None),
            ("Pizza Yop", "restauration", "pizza, italien, livraison", "Yopougon", "+2250700000004", 5.3400000, -4.0950000, 1, None),
            ("TAXIJET", "transport", "taxi, course, aeroport, deplacement", "Abidjan", "+2252522007800", 5.4024785, -3.9965032, 1, None),
            ("Moto Rapide", "transport", "moto, taxi moto, course rapide", "Yopougon", "+2250700000006", 5.3380000, -4.0900000, 1, None),
        ]
        curseur.executemany(
            """INSERT INTO prestataires
               (nom, categorie, mots_cles, ville, telephone, latitude, longitude, disponible, photo_url)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            prestataires_de_base,
        )

    connexion.commit()
    connexion.close()

_initialiser_base()

# ============================================================
# FONCTIONS POUR LES UTILISATEURS
# ============================================================

def enregistrer_utilisateur(first_name, last_name, email, whatsapp, password):
    """Enregistre un nouvel utilisateur dans la base de données."""
    
    # 🔥 VALIDATION DU NUMÉRO WHATSAPP
    if not valider_whatsapp(whatsapp):
        return None, "Numéro WhatsApp invalide. Format : +225XXXXXXXXXX (10 chiffres)"
    
    connexion = sqlite3.connect("chatgo.db")
    connexion.row_factory = sqlite3.Row
    curseur = connexion.cursor()
    
    try:
        # Vérifier si l'email existe déjà
        curseur.execute("SELECT id FROM utilisateurs WHERE email = ?", (email,))
        if curseur.fetchone():
            connexion.close()
            return None, "Cet email est déjà utilisé"
        
        # Nettoyer le numéro WhatsApp avant de le stocker
        whatsapp_clean = re.sub(r'\s', '', whatsapp.strip())
        
        # Insérer le nouvel utilisateur
        curseur.execute("""
            INSERT INTO utilisateurs 
            (first_name, last_name, email, whatsapp, password, created_at, last_login)
            VALUES (?, ?, ?, ?, ?, ?, NULL)
        """, (first_name, last_name, email, whatsapp_clean, password, datetime.now()))
        
        connexion.commit()
        user_id = curseur.lastrowid
        
        # Récupérer l'utilisateur créé
        curseur.execute("SELECT * FROM utilisateurs WHERE id = ?", (user_id,))
        user = dict(curseur.fetchone())
        connexion.close()
        
        return user, None
        
    except Exception as e:
        connexion.close()
        return None, str(e)

def connecter_utilisateur(email, password):
    """Connecte un utilisateur existant."""
    connexion = sqlite3.connect("chatgo.db")
    connexion.row_factory = sqlite3.Row
    curseur = connexion.cursor()
    
    try:
        # Chercher l'utilisateur par email
        curseur.execute("SELECT * FROM utilisateurs WHERE email = ?", (email,))
        user = curseur.fetchone()
        
        if not user:
            connexion.close()
            return None, "Email non trouvé"
        
        # Vérifier le mot de passe
        if user["password"] != password:
            connexion.close()
            return None, "Mot de passe incorrect"
        
        # Vérifier si c'est la première connexion
        is_first_login = user["last_login"] is None
        
        # Mettre à jour last_login
        curseur.execute("""
            UPDATE utilisateurs 
            SET last_login = ? 
            WHERE id = ?
        """, (datetime.now(), user["id"]))
        connexion.commit()
        
        user_dict = dict(user)
        user_dict["isFirstLogin"] = is_first_login
        
        connexion.close()
        return user_dict, None
        
    except Exception as e:
        connexion.close()
        return None, str(e)

# ============================================================
# FONCTIONS POUR LES PRESTATAIRES
# ============================================================

def _normaliser(mot: str) -> str:
    mot = mot.strip().lower()
    mot = unicodedata.normalize("NFKD", mot)
    return "".join(c for c in mot if not unicodedata.combining(c))

def _similaires(mot_a: str, mot_b: str, seuil: float = 0.6) -> bool:
    return SequenceMatcher(None, mot_a, mot_b).ratio() >= seuil

def rechercher_prestataires(categorie: str, mots_cles: list, limite: int = 3):
    connexion = sqlite3.connect("chatgo.db")
    connexion.row_factory = sqlite3.Row
    curseur = connexion.cursor()

    curseur.execute(
        "SELECT * FROM prestataires WHERE categorie = ? AND disponible = 1",
        (categorie,),
    )
    lignes = [dict(ligne) for ligne in curseur.fetchall()]
    connexion.close()

    if not lignes:
        return []

    if not mots_cles:
        return lignes[:limite]

    mots_cles_utilisateur = {_normaliser(mot) for mot in mots_cles}

    def score(prestataire):
        mots_prestataire = {
            _normaliser(mot) for mot in prestataire["mots_cles"].split(",")
        }
        total = 0
        for mot_u in mots_cles_utilisateur:
            if any(_similaires(mot_u, mot_p) for mot_p in mots_prestataire):
                total += 1
        return total

    lignes.sort(key=score, reverse=True)
    lignes_pertinentes = [ligne for ligne in lignes if score(ligne) > 0]

    return lignes_pertinentes[:limite]

# ============================================================
# PROMPT SYSTEM
# ============================================================

SYSTEM_PROMPT = """Tu es l'assistant virtuel chaleureux, très accueillant et amical de l'application Chat&Go en Côte d'Ivoire.

Ta tâche : analyser le message de l'utilisateur et retourner UNIQUEMENT un objet JSON valide, sans aucun texte avant ou après.

RÈGLES DE CATÉGORISATION :
1. "salutation" : Si le message est UNIQUEMENT une salutation (bonjour, salut, coucou, hello, hey, yo, bonsoir, bien le bonjour) SANS mention de service.
   → reponse_amicale DOIT contenir une réponse chaleureuse.

2. "depannage" : plomberie, électricité, serrurerie, mécanique, fuite, panne
3. "restauration" : restaurant, maquis, pizza, grill, livraison
4. "transport" : taxi, moto-taxi, déménagement, course
5. "sante" : pharmacie, clinique, médecin
6. "beaute" : coiffeur, salon de beauté, barbier
7. "commerce" : boutique, supermarché, magasin
8. "autre" : si aucune catégorie ne correspond

RÈGLES IMPORTANTES :
- Si le message contient une salutation ET une demande de service (ex: "Bonjour, je cherche un plombier") → catégorie = le service, reponse_amicale = null
- Si le message est une salutation PURE → catégorie = "salutation", reponse_amicale = réponse sympa

EXEMPLES :
Message: "Bonjour"
→ {"categorie":"salutation","mots_cles":[],"ville":null,"urgence":false,"reponse_amicale":"Bonjour ! Bienvenue sur Chat&Go 😊 Quel service recherchez-vous aujourd'hui ?"}

Message: "Salut, je cherche un plombier"
→ {"categorie":"depannage","mots_cles":["plombier"],"ville":null,"urgence":false,"reponse_amicale":null}

Message: "Je veux une pizza"
→ {"categorie":"restauration","mots_cles":["pizza"],"ville":null,"urgence":false,"reponse_amicale":null}

Message: "Quelle heure est-il ?"
→ {"categorie":"autre","mots_cles":[],"ville":null,"urgence":false,"reponse_amicale":"Je suis un assistant pour trouver des services. Que cherchez-vous (plombier, restaurant, taxi...) ?"}

Ne réponds JAMAIS avec une explication, seulement le JSON."""

# ============================================================
# ENDPOINTS UTILISATEURS
# ============================================================

@app.post("/register")
def inscription(data: InscriptionRequest):
    """Endpoint d'inscription des nouveaux utilisateurs."""
    
    user, error = enregistrer_utilisateur(
        data.first_name,
        data.last_name,
        data.email,
        data.whatsapp,
        data.password
    )
    
    if error:
        raise HTTPException(status_code=400, detail=error)
    
    return {
        "message": "Inscription réussie",
        "user": {
            "id": user["id"],
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "email": user["email"],
            "whatsapp": user["whatsapp"],
            "created_at": user["created_at"],
            "is_new_user": True
        }
    }

@app.post("/login")
def connexion(data: ConnexionRequest):
    """Endpoint de connexion des utilisateurs existants."""
    
    user, error = connecter_utilisateur(data.email, data.password)
    
    if error:
        raise HTTPException(status_code=401, detail=error)
    
    return {
        "message": "Connexion réussie",
        "user": {
            "id": user["id"],
            "first_name": user["first_name"],
            "last_name": user["last_name"],
            "email": user["email"],
            "whatsapp": user["whatsapp"],
            "created_at": user["created_at"],
            "last_login": user["last_login"],
            "isFirstLogin": user["isFirstLogin"]
        }
    }

# ============================================================
# ENDPOINT D'ANALYSE
# ============================================================

@app.post("/analyser")
def analyser(message: MessageEntrant):
    """Analyse le message de l'utilisateur avec DeepSeek."""

    if not DEEPSEEK_API_KEY:
        raise HTTPException(
            status_code=500,
            detail="Variable d'environnement DEEPSEEK_API_KEY manquante.",
        )

    payload = {
        "model": "deepseek-chat",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": message.texte},
        ],
        "temperature": 0.2,
    }
    headers = {
        "Authorization": f"Bearer {DEEPSEEK_API_KEY}",
        "Content-Type": "application/json",
    }

    reponse = requests.post(DEEPSEEK_URL, headers=headers, json=payload, timeout=20)
    reponse.raise_for_status()

    contenu_brut = reponse.json()["choices"][0]["message"]["content"]

    try:
        intention = json.loads(contenu_brut)
    except json.JSONDecodeError:
        raise HTTPException(
            status_code=502,
            detail=f"Réponse DeepSeek non-JSON reçue : {contenu_brut}",
        )

    categorie = intention.get("categorie")
    reponse_amicale = intention.get("reponse_amicale")

    if categorie in ["salutation", "autre"]:
        return {
            "intention": intention,
            "prestataires": [],
            "reponse_amicale": reponse_amicale,
        }

    prestataires = rechercher_prestataires(
        categorie, intention.get("mots_cles", [])
    )

    if len(prestataires) < 3:
        noms_deja_trouves = {_normaliser(p["nom"]) for p in prestataires}
        complement = rechercher_en_ligne(
            categorie,
            intention.get("mots_cles", []),
            intention.get("ville"),
            limite=3 - len(prestataires),
            noms_existants=noms_deja_trouves,
        )
        prestataires = prestataires + complement

    return {
        "intention": intention,
        "prestataires": prestataires,
        "reponse_amicale": None,
    }

# ============================================================
# FONCTION DE RECHERCHE EN LIGNE
# ============================================================

def rechercher_en_ligne(categorie: str, mots_cles: list, ville: str | None, limite: int = 3, noms_existants: set | None = None):
    if not SERPAPI_KEY:
        return []

    noms_existants = noms_existants or set()
    ville_recherche = ville or "Abidjan"
    requete = " ".join(mots_cles[:2]) if mots_cles else categorie
    requete = f"{requete} {ville_recherche}"

    params = {
        "engine": "google_maps",
        "q": requete,
        "type": "search",
        "api_key": SERPAPI_KEY,
    }

    try:
        reponse = requests.get(SERPAPI_URL, params=params, timeout=15)
        reponse.raise_for_status()
        donnees = reponse.json()
    except requests.RequestException as erreur:
        print(f"[SerpAPI] Erreur lors de la requête : {erreur}", flush=True)
        return []

    if "error" in donnees:
        print(f"[SerpAPI] Erreur renvoyée par l'API : {donnees['error']}", flush=True)
        return []

    resultats = donnees.get("local_results", [])
    if not resultats:
        print(f"[SerpAPI] Aucun local_results pour la requête : '{requete}'", flush=True)
        return []

    mots_cles_str = ", ".join(mots_cles) if mots_cles else categorie
    prestataires_trouves = []

    for resultat in resultats:
        if len(prestataires_trouves) >= limite:
            break

        nom = resultat.get("title")
        telephone = resultat.get("phone")
        gps = resultat.get("gps_coordinates", {})
        latitude = gps.get("latitude")
        longitude = gps.get("longitude")
        photo_url = resultat.get("thumbnail")
        adresse = resultat.get("address") or ville_recherche

        if not nom or not telephone or latitude is None or longitude is None:
            continue
        if _normaliser(nom) in noms_existants:
            continue

        prestataire = _enregistrer_prestataire(
            nom, categorie, mots_cles_str, adresse, telephone, latitude, longitude, photo_url
        )
        prestataires_trouves.append(prestataire)
        noms_existants.add(_normaliser(nom))

    return prestataires_trouves

def _enregistrer_prestataire(nom, categorie, mots_cles_str, ville, telephone, latitude, longitude, photo_url=None):
    # Nettoyer le numéro de téléphone
    telephone_clean = re.sub(r'\s', '', telephone.strip())
    
    connexion = sqlite3.connect("chatgo.db")
    curseur = connexion.cursor()
    curseur.execute(
        """INSERT INTO prestataires
           (nom, categorie, mots_cles, ville, telephone, latitude, longitude, disponible, photo_url)
           VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)""",
        (nom, categorie, mots_cles_str, ville, telephone_clean, latitude, longitude, photo_url),
    )
    connexion.commit()
    connexion.close()

    return {
        "nom": nom,
        "categorie": categorie,
        "mots_cles": mots_cles_str,
        "ville": ville,
        "telephone": telephone_clean,
        "latitude": latitude,
        "longitude": longitude,
        "disponible": 1,
        "photo_url": photo_url,
    }

@app.get("/")
def racine():
    return {"statut": "Chat&Go backend actif"}