"""
Script à lancer UNE SEULE FOIS pour compléter la photo des prestataires
déjà enregistrés en base avant qu'on ajoute la colonne photo_url.

Contrairement à creer_base.py, ce script ne supprime rien : il met juste
à jour (UPDATE) les lignes existantes qui n'ont pas encore de photo.

Attention : chaque prestataire sans photo consomme une recherche sur ton
quota gratuit SerpAPI (100/mois). Lance ce script une seule fois.
"""

import os
import sqlite3
import requests
from dotenv import load_dotenv

load_dotenv()

SERPAPI_KEY = os.environ.get("SERPAPI_KEY")
SERPAPI_URL = "https://serpapi.com/search"


def chercher_photo(nom: str, ville: str) -> str | None:
    """Cherche le prestataire par son nom sur SerpAPI et renvoie sa photo
    si elle est trouvée, sinon None."""
    params = {
        "engine": "google_maps",
        "q": f"{nom} {ville}",
        "type": "search",
        "api_key": SERPAPI_KEY,
    }
    try:
        reponse = requests.get(SERPAPI_URL, params=params, timeout=15)
        reponse.raise_for_status()
        resultats = reponse.json().get("local_results", [])
    except requests.RequestException:
        return None

    if not resultats:
        return None

    return resultats[0].get("thumbnail")


def completer_les_photos_manquantes():
    if not SERPAPI_KEY:
        print("SERPAPI_KEY manquante dans .env, impossible de continuer.")
        return

    connexion = sqlite3.connect("chatgo.db")
    connexion.row_factory = sqlite3.Row
    curseur = connexion.cursor()

    curseur.execute(
        "SELECT id, nom, ville FROM prestataires WHERE photo_url IS NULL OR photo_url = ''"
    )
    a_completer = curseur.fetchall()

    print(f"{len(a_completer)} prestataire(s) sans photo trouvé(s).")

    for ligne in a_completer:
        print(f"Recherche d'une photo pour : {ligne['nom']}...")
        photo = chercher_photo(ligne["nom"], ligne["ville"])

        if photo:
            curseur.execute(
                "UPDATE prestataires SET photo_url = ? WHERE id = ?",
                (photo, ligne["id"]),
            )
            connexion.commit()
            print(f"  -> photo trouvée et enregistrée.")
        else:
            print(f"  -> aucune photo trouvée, laissé tel quel.")

    connexion.close()
    print("Terminé.")


if __name__ == "__main__":
    completer_les_photos_manquantes()