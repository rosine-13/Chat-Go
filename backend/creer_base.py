import sqlite3

connexion = sqlite3.connect("chatgo.db")
curseur = connexion.cursor()

# Supprime l'ancienne table
curseur.execute("DROP TABLE IF EXISTS prestataires")

# Création de la table avec toutes les colonnes nécessaires (photo_url, adresse, note, nombre_avis)
curseur.execute("""
CREATE TABLE prestataires (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom TEXT NOT NULL,
    categorie TEXT NOT NULL,
    mots_cles TEXT NOT NULL,
    ville TEXT NOT NULL,
    telephone TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    photo_url TEXT,
    adresse TEXT,
    note REAL DEFAULT 0.0,
    nombre_avis INTEGER DEFAULT 0,
    disponible INTEGER NOT NULL DEFAULT 1
)
""")

# Données de test enrichies avec photos, adresses et notes Google/Local
prestataires_test = [
    (
        "AS DE LA PLOMBERIE",
        "depannage",
        "plomberie, plombier, fuite, eau, urgence",
        "Abidjan",
        "+2250707767555",
        5.3080321,
        -4.0878349,
        "https://images.unsplash.com/photo-1581578731548-c64695cc6952?q=80&w=400",
        "Treichville, Abidjan",
        4.5,
        28,
        1,
    ),
    (
        "Electro Rapide CI",
        "depannage",
        "electricite, electricien, panne, courant, clim",
        "Cocody",
        "+2250700000002",
        5.3450000,
        -4.0100000,
        "https://images.unsplash.com/photo-1621905251189-08b45d6a269e?q=80&w=400",
        "Angré 8ème Tranche, Cocody",
        4.8,
        15,
        1,
    ),
    (
        "Texas GrillZ Yopougon",
        "restauration",
        "restaurant, grill, cuisine, maquis",
        "Yopougon",
        "+2250777450000",
        5.3436561,
        -4.1002879,
        "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?q=80&w=400",
        "Siporex, Yopougon",
        4.2,
        42,
        1,
    ),
    (
        "Pizza Yop",
        "restauration",
        "pizza, italien, livraison",
        "Yopougon",
        "+2250700000004",
        5.3400000,
        -4.0950000,
        "https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400",
        "Maroc, Yopougon",
        4.0,
        10,
        1,
    ),
    (
        "TAXIJET",
        "transport",
        "taxi, course, aeroport, deplacement",
        "Abidjan",
        "+2252522007800",
        5.4024785,
        -3.9965032,
        "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?q=80&w=400",
        "Aéroport Félix Houphouët-Boigny, Port-Bouët",
        4.6,
        89,
        1,
    ),
    (
        "Moto Rapide",
        "transport",
        "moto, taxi moto, course rapide",
        "Yopougon",
        "+2250700000006",
        5.3380000,
        -4.0900000,
        "https://images.unsplash.com/photo-1558981806-ec527fa84c39?q=80&w=400",
        "Niangon, Yopougon",
        4.3,
        7,
        1,
    ),
]

curseur.executemany("""
INSERT INTO prestataires 
(nom, categorie, mots_cles, ville, telephone, latitude, longitude, photo_url, adresse, note, nombre_avis, disponible)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
""", prestataires_test)

connexion.commit()
connexion.close()

print(f"Base réinitialisée avec succès : {len(prestataires_test)} prestataires configurés.")