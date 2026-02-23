# Exemple de données à soumettre pour la fonction addVente

## URL de l'API
```
POST /api/add-vente
Headers: 
- Authorization: Bearer <votre_token>
- Content-Type: application/json
```

## Structure des données requises

### Données complètes à soumettre (JSON)

```json
{
  "client": "Jean Dupont",
  "vendeur_id": 1,
  "type_vente": "comptant",
  "montant_total": 1600.00,
  "articles": [
    {
      "produit_id": 1,
      "quantite": 2,
      "prix_unitaire": 500.00
    },
    {
      "produit_id": 3,
      "quantite": 1,
      "prix_unitaire": 600.00
    }
  ]
}
```

## Description des champs

### Champs principaux
- **client** (string, optionnel) : Nom du client. Si non fourni, utilise "Client Anonyme"
- **vendeur_id** (integer, optionnel) : ID du vendeur. Si non fourni, utilise l'ID de l'utilisateur authentifié
- **type_vente** (string, optionnel) : Type de vente. Valeurs possibles : "comptant" ou "credit". Par défaut "comptant"
- **montant_total** (decimal, requis) : Montant total de la vente
- **articles** (array, requis) : Liste des articles vendus

### Champs des articles
- **produit_id** (integer, requis) : ID du produit (doit exister dans la table produits)
- **quantite** (integer, requis) : Quantité vendue (minimum 1)
- **prix_unitaire** (decimal, requis) : Prix unitaire de l'article

## Exemples concrets

### Exemple 1: Vente simple avec paiement comptant
```json
{
  "client": "Marie Claire",
  "type_vente": "comptant",
  "montant_total": 2500.00,
  "articles": [
    {
      "produit_id": 5,
      "quantite": 1,
      "prix_unitaire": 2500.00
    }
  ]
}
```

### Exemple 2: Vente multiple avec crédit
```json
{
  "client": "Pharmacie Centrale",
  "vendeur_id": 2,
  "type_vente": "credit",
  "montant_total": 4500.00,
  "articles": [
    {
      "produit_id": 1,
      "quantite": 3,
      "prix_unitaire": 1000.00
    },
    {
      "produit_id": 7,
      "quantite": 2,
      "prix_unitaire": 750.00
    },
    {
      "produit_id": 12,
      "quantite": 1,
      "prix_unitaire": 300.00
    }
  ]
}
```

### Exemple 3: Vente avec client anonyme
```json
{
  "montant_total": 1200.00,
  "articles": [
    {
      "produit_id": 3,
      "quantite": 2,
      "prix_unitaire": 600.00
    }
  ]
}
```

## Validation des données

### Règles de validation
- `montant_total`: requis, doit être numérique
- `articles`: requis, doit être un tableau
- `articles.*.produit_id`: requis, doit exister dans la table produits
- `articles.*.quantite`: requis, entier, minimum 1
- `articles.*.prix_unitaire`: requis, numérique

### Erreurs possibles
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "montant_total": ["Le montant total est requis."],
    "articles": ["La liste des articles est requise."],
    "articles.0.produit_id": ["Le produit sélectionné n'existe pas."]
  }
}
```

## Réponse en cas de succès

```json
{
  "message": "Vente ajoutée avec succès",
  "vente": {
    "id": 123,
    "client": "Jean Dupont",
    "vendeur_id": 1,
    "type_vente": "comptant",
    "montant_total": 1600.00,
    "pharmacie_id": 1,
    "created_at": "2026-02-22T15:30:00.000000Z",
    "updated_at": "2026-02-22T15:30:00.000000Z",
    "venteDetails": [
      {
        "id": 456,
        "vente_id": 123,
        "produit_id": 1,
        "quantite": 2,
        "prix_unitaire": 500.00,
        "total": 1000.00,
        "created_at": "2026-02-22T15:30:00.000000Z",
        "updated_at": "2026-02-22T15:30:00.000000Z"
      }
    ],
    "vendeur": {
      "id": 1,
      "name": "Admin",
      "email": "admin@pharmacie.com"
    }
  }
}
```

## Notes importantes

1. **Stock automatique**: La fonction met automatiquement à jour le stock en déduisant les quantités vendues
2. **Mouvement de stock**: Un mouvement de stock de type "sortie" est automatiquement créé
3. **Historique**: L'action est enregistrée dans l'historique d'audit
4. **Transaction**: Toute l'opération est transactionnelle (rollback si erreur)
5. **Validation**: Le stock disponible est vérifié avant la vente

## Test avec curl

```bash
curl -X POST http://localhost:8001/api/add-vente \
  -H "Authorization: Bearer votre_token" \
  -H "Content-Type: application/json" \
  -d '{
    "client": "Test Client",
    "type_vente": "comptant",
    "montant_total": 1600.00,
    "articles": [
      {
        "produit_id": 1,
        "quantite": 2,
        "prix_unitaire": 500.00
      }
    ]
  }'
```
