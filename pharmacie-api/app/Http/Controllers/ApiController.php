<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Pharmacie;
use App\Models\User;
use App\Models\historique;
use App\Models\Stock;
use App\Models\Produit;
use App\Models\Vente;
use App\Models\Approvisionnement;
use App\Models\ApprovisionnementDetail;
use App\Models\VenteDetail;
use App\Models\MouvementStock;
use App\Models\Categorie;
use App\Models\Fournisseur;
use App\Models\Role;
use App\Models\Client;
use App\Models\JournalAudit;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;

class ApiController extends Controller
{
    /////////// Auth API ///////////

    //Ajout de l'historique de l'application
    public function addHistorique(string $action, string $description = null)
    {
        $user = Auth::user();
        
        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $historique = historique::create([
            'user_id' => $user->id,
            'action' => $action,
            'description' => $description ?? 'Action effectuée',
        ]);

        return response()->json([
            'message' => 'Historique ajouté avec succès',
            'historique' => $historique
        ], 201);
    }

    // Enregistrement d'un nouvelle pharmacie
    public function register(Request $request)
    {
        $validated = $request->validate([
            'nom' => 'required|string|max:150',
            'telephone' => 'nullable|string|max:20',
            'adresse' => 'nullable|string|max:255',
        ]);

        $pharmacie = Pharmacie::create($validated);
        
        return response()->json([
            'message' => 'Pharmacie créée avec succès',
            'pharmacie' => $pharmacie
        ], 201);
    }
    
    //Connexion des utilisateur
    // public function login(Request $request)
    // {
    //     $credentials = $request->validate([
    //         'email' => 'required|email',
    //         'password' => 'required',
    //     ]);
        
    //     if (Auth::attempt($credentials)) {
    //         $user = Auth::user();
    //         $token = $user->createToken('pharmacie-api')->plainTextToken;
            
    //         return response()->json([
    //             'message' => 'Connexion réussie',
    //             'token' => $token,
    //             'user' => $user
    //         ], 200);
    //     }
        
    //     return response()->json([
    //         'message' => 'Identifiants invalides'
    //     ], 401);
    // }
    public function login(Request $request)
    {
        //Validation
        $validated = $request->validate([
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        //Récupérer l'utilisateur
        $user = User::where('email', $validated['email'])->first();

        //Vérifier si utilisateur existe et mot de passe correct
        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Identifiants invalides'
            ], 401);
        }

        //Vérifier si l'utilisateur est actif
        if (!$user->actif) {
            return response()->json([
                'message' => 'Utilisateur désactivé'
            ], 403);
        }


        //Créer un token API via Sanctum
        $token = $user->createToken('pharmacie-api')->plainTextToken;

        $this->addHistorique('Connexion réussie');

        //Retour JSON avec seulement les champs nécessaires
        return response()->json([
            'message' => 'Connexion réussie',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'role_id' => $user->role_id,
                'pharmacie_id' => $user->pharmacie_id,
                'nom' => $user->pharmacie->nom,
                'actif' => $user->actif,
            ]
        ], 200);
    }
    
    //Creation des utilisateurs
    public function createUser(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:150',
            'email' => 'required|email|unique:users',
            'pharmacie_id' => 'required|exists:pharmacies,id',
            'role_id' => 'required|exists:roles,id',
            'password' => 'required|string|min:8',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'pharmacie_id' => $validated['pharmacie_id'],
            'role_id' => $validated['role_id'],
            'actif' => true,
        ]);

        return response()->json([
            'message' => 'Utilisateur créé avec succès',
            'user' => $user
        ], 201);
    }

    //Liste des stocks
    public function getStock()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        
        $this->addHistorique('Accès à la liste des stocks');

        // Récupérer les stocks avec les informations du produit
        $stocks = Stock::with('produit')
            ->whereHas('produit', function($query) use ($user) {
                $query->where('pharmacie_id', $user->pharmacie_id);
            })
            ->get()
            ->map(function ($item) {
                return [
                    'id' => $item->id,
                    'produit_id' => $item->produit_id,
                    'produit_nom' => $item->produit ? $item->produit->nom : 'Produit inconnu',
                    'quantite' => $item->quantite,
                    'seuil_alerte' => $item->seuil_alerte,
                    'statut' => $item->quantite <= $item->seuil_alerte ? 'Alerte' : 'Normal',
                    'created_at' => $item->created_at->format('Y-m-d H:i:s'),
                ];
            });

        return response()->json([
            'message' => 'Liste des stocks',
            'stocks' => $stocks,
            'total' => $stocks->count(),
            'alertes' => $stocks->where('statut', 'Alerte')->count(),
        ], 200);
    }

    //Liste des historiques
    public function getHistoriques()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        
        $this->addHistorique('Accès à l\'historique d\'audit');

        // Récupérer les historiques avec pagination et filtrage par pharmacie
        $historiques = historique::with('user')
            ->whereHas('user', function($query) use ($user) {
                $query->where('pharmacie_id', $user->pharmacie_id);
            })
            ->orderBy('created_at', 'desc')
            ->paginate(50)
            ->through(function ($item) {
                return [
                    'id' => $item->id,
                    'action' => $item->action,
                    'description' => $item->description,
                    'user_name' => $item->user ? $item->user->name : 'Utilisateur inconnu',
                    'user_email' => $item->user ? $item->user->email : 'email@inconnu.com',
                    'created_at' => $item->created_at->format('Y-m-d H:i:s'),
                    'formatted_date' => $item->created_at->format('d/m/Y H:i'),
                    'type' => $this->getActionType($item->action),
                ];
            });

        return response()->json([
            'message' => 'Liste des historiques',
            'historiques' => $historiques->items(),
            'pagination' => [
                'current_page' => $historiques->currentPage(),
                'per_page' => $historiques->perPage(),
                'total' => $historiques->total(),
                'last_page' => $historiques->lastPage(),
            ],
            'stats' => [
                'total' => $historiques->total(),
                'aujourd_hui' => $this->getTodayHistoriquesCount($user->pharmacie_id),
                'cette_semaine' => $this->getWeekHistoriquesCount($user->pharmacie_id),
            ]
        ], 200);
    }

    // Helper pour déterminer le type d'action
    private function getActionType($action)
    {
        $actionLower = strtolower($action);
        
        if (strpos($actionLower, 'connexion') !== false || strpos($actionLower, 'login') !== false) {
            return 'AUTH';
        } elseif (strpos($actionLower, 'déconnexion') !== false || strpos($actionLower, 'logout') !== false) {
            return 'AUTH';
        } elseif (strpos($actionLower, 'création') !== false || strpos($actionLower, 'ajout') !== false) {
            return 'CRUD';
        } elseif (strpos($actionLower, 'modification') !== false || strpos($actionLower, 'mise à jour') !== false) {
            return 'CRUD';
        } elseif (strpos($actionLower, 'suppression') !== false || strpos($actionLower, 'delete') !== false) {
            return 'CRUD';
        } elseif (strpos($actionLower, 'accès') !== false || strpos($actionLower, 'consultation') !== false) {
            return 'VIEW';
        }
        
        return 'AUTRE';
    }

    // Helper pour compter les historiques d'aujourd'hui
    private function getTodayHistoriquesCount($pharmacieId)
    {
        return historique::whereHas('user', function($query) use ($pharmacieId) {
                $query->where('pharmacie_id', $pharmacieId);
            })
            ->whereDate('created_at', today())
            ->count();
    }

    // Helper pour compter les historiques de la semaine
    private function getWeekHistoriquesCount($pharmacieId)
    {
        return historique::whereHas('user', function($query) use ($pharmacieId) {
                $query->where('pharmacie_id', $pharmacieId);
            })
            ->whereBetween('created_at', [now()->startOfWeek(), now()->endOfWeek()])
            ->count();
    }

    //Liste des produits
    public function getProduits()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        
        $this->addHistorique('Accès à la liste des produits');

        // Logique pour récupérer les produits
        // $produits = Produit::where('pharmacie_id', $user->pharmacie_id)->get();
        $produits = Produit::with('categorie','fournisseur', 'stock', 'venteDetails', 'approvisionnementDetails', 'mouvementsStock')->where('pharmacie_id', $user->pharmacie_id)->get();
        return response()->json([
            'message' => 'Liste des produits',
            'produits' => $produits, // À remplacer par la vraie logique
        ], 200);
    }

    //Liste des ventes
    public function getVentes()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
            $this->addHistorique('Accès refusé - Utilisateur non identifié');
        }
        $this->addHistorique('Accès à la liste des ventes');

        // Logique pour récupérer les ventes
        $ventes = Vente::with('client', 'vendeur', 'venteDetails.produit')->where('pharmacie_id', $user->pharmacie_id)->get();
        return response()->json([
            'message' => 'Liste des ventes',
            'ventes' => $ventes, // À remplacer par la vraie logique
        ], 200);
    }

    //Liste des utilisateurs
    public function getUsers(){
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        $this->addHistorique('Accès à la liste des utilisateurs');

        // Logique pour récupérer les utilisateurs
        $users = User::with('role')
            ->where('pharmacie_id', $user->pharmacie_id)
            ->orderBy('created_at', 'desc')
            ->get();
        return response()->json([
            'message' => 'Liste des utilisateurs',
            'users' => $users, // À remplacer par la vraie logique
        ], 200);
    }

    ////INSERTIONS DES DONNEES 

    //Ajout d'une vente
    public function addVente(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $request->validate([
            'montant_total' => 'required|numeric',
            'articles' => 'required|array',
            'articles.*.produit_id' => 'required|exists:produits,id',
            'articles.*.quantite' => 'required|integer|min:1',
            'articles.*.prix_unitaire' => 'required|numeric',
        ]);

        try {
            DB::beginTransaction();

            $vente = Vente::create([
                'client_id' => $request->client_id ?? 'Client Anonyme',
                'vendeur_id' => $request->vendeur_id ?? $user->id,
                'type_vente' => $request->type_vente ?? 'comptant',
                'montant_total' => $request->montant_total,
                'pharmacie_id' => $user->pharmacie_id,
            ]);

            foreach ($request->articles as $article) {
                // Création du détail de vente
                VenteDetail::create([
                    'vente_id' => $vente->id,
                    'produit_id' => $article['produit_id'],
                    'quantite' => $article['quantite'],
                    'prix_unitaire' => $article['prix_unitaire'],
                    'total' => $article['quantite'] * $article['prix_unitaire'],
                ]);

                // Mise à jour du stock
                $stock = Stock::where('produit_id', $article['produit_id'])->first();
                if (!$stock || $stock->quantite < $article['quantite']) {
                    throw new \Exception("Stock insuffisant pour le produit ID: " . $article['produit_id']);
                }
                
                $stock->quantite -= $article['quantite'];
                $stock->save();

                // Création du mouvement de stock (sortie)
                MouvementStock::create([
                    'pharmacie_id' => $user->pharmacie_id,
                    'produit_id' => $article['produit_id'],
                    'type' => 'sortie',
                    'quantite' => $article['quantite'],
                    'reference' => 'Vente_#' . $vente->id,
                    'user_id' => $user->id,
                ]);
            }

            DB::commit();
            $this->addHistorique('Ajout d\'une vente #' . $vente->id);

            // Recharger la vente avec ses relations pour la réponse
            $vente->load('venteDetails', 'vendeur');

            return response()->json([
                'message' => 'Vente ajoutée avec succès',
                'vente' => $vente,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur lors de la vente: ' . $e->getMessage()
            ], 500);
        }
    }

    // ==================== CRUD APPROVISIONNEMENT ====================

    //Liste des approvisionnements
    public function getApprovisionnements()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        
        $this->addHistorique('Accès à la liste des approvisionnements');

        $approvisionnements = Approvisionnement::with('fournisseur', 'user', 'approvisionnementDetails.produit')
            ->where('pharmacie_id', $user->pharmacie_id)
            ->orderBy('created_at', 'desc')
            ->get();
            
        return response()->json([
            'message' => 'Liste des approvisionnements',
            'approvisionnements' => $approvisionnements,
            'total' => $approvisionnements->count(),
        ], 200);
    }

    //Liste des fournisseurs
    public function getFournisseurs()
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }
        
        $this->addHistorique('Accès à la liste des fournisseurs');

        $fournisseurs = Fournisseur::where('pharmacie_id', $user->pharmacie_id)
            ->orderBy('nom', 'asc')
            ->get();
            
        return response()->json([
            'message' => 'Liste des fournisseurs',
            'fournisseurs' => $fournisseurs,
        ], 200);
    }

    //Ajout d'un approvisionnement
    public function addApprovisionnement(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $request->validate([
            'fournisseur_id' => 'required|exists:fournisseurs,id',
            'montant_total' => 'required|numeric',
            'articles' => 'required|array',
            'articles.*.produit_id' => 'required|exists:produits,id',
            'articles.*.quantite' => 'required|integer|min:1',
            'articles.*.prix_achat' => 'required|numeric|min:0',
        ]);

        try {
            DB::beginTransaction();

            $approvisionnement = Approvisionnement::create([
                'fournisseur_id' => $request->fournisseur_id,
                'user_id' => $user->id,
                'montant_total' => $request->montant_total,
                'pharmacie_id' => $user->pharmacie_id,
            ]);

            foreach ($request->articles as $article) {
                // Création du détail d'approvisionnement
                ApprovisionnementDetail::create([
                    'approvisionnement_id' => $approvisionnement->id,
                    'produit_id' => $article['produit_id'],
                    'quantite' => $article['quantite'],
                    'prix_achat' => $article['prix_achat'],
                    'total' => $article['quantite'] * $article['prix_achat'],
                ]);

                // Mise à jour du stock
                $stock = Stock::where('produit_id', $article['produit_id'])->first();
                if ($stock) {
                    $stock->quantite += $article['quantite'];
                    $stock->save();
                } else {
                    // Créer le stock s'il n'existe pas
                    Stock::create([
                        'produit_id' => $article['produit_id'],
                        'quantite' => $article['quantite'],
                        'seuil_alerte' => 10, // Valeur par défaut
                    ]);
                }

                // Création du mouvement de stock (entrée)
                MouvementStock::create([
                    'pharmacie_id' => $user->pharmacie_id,
                    'produit_id' => $article['produit_id'],
                    'type' => 'entree',
                    'quantite' => $article['quantite'],
                    'reference' => 'Approvisionnement_#' . $approvisionnement->id,
                    'user_id' => $user->id,
                ]);
            }

            DB::commit();
            $this->addHistorique('Ajout d\'un approvisionnement #' . $approvisionnement->id);

            // Recharger l'approvisionnement avec ses relations pour la réponse
            $approvisionnement->load('fournisseur', 'user', 'approvisionnementDetails.produit');

            return response()->json([
                'message' => 'Approvisionnement ajouté avec succès',
                'approvisionnement' => $approvisionnement,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur lors de l\'approvisionnement: ' . $e->getMessage()
            ], 500);
        }
    }

    //Suppression d'un approvisionnement
    public function deleteApprovisionnement($id)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $approvisionnement = Approvisionnement::where('id', $id)
            ->where('pharmacie_id', $user->pharmacie_id)
            ->first();

        if (!$approvisionnement) {
            return response()->json([
                'message' => 'Approvisionnement non trouvé'
            ], 404);
        }

        try {
            DB::beginTransaction();

            // Annuler les mouvements de stock
            foreach ($approvisionnement->approvisionnementDetails as $detail) {
                $stock = Stock::where('produit_id', $detail->produit_id)->first();
                if ($stock) {
                    $stock->quantite -= $detail->quantite;
                    $stock->save();
                }

                // Supprimer le mouvement de stock correspondant
                MouvementStock::where('reference', 'Approvisionnement_#' . $approvisionnement->id)
                    ->where('produit_id', $detail->produit_id)
                    ->delete();
            }

            // Supprimer les détails puis l'approvisionnement
            $approvisionnement->approvisionnementDetails()->delete();
            $approvisionnement->delete();

            DB::commit();
            $this->addHistorique('Suppression de l\'approvisionnement #' . $id);

            return response()->json([
                'message' => 'Approvisionnement supprimé avec succès'
            ], 200);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur lors de la suppression: ' . $e->getMessage()
            ], 500);
        }
    }

    //Ajout d'un fournisseur
    public function addFournisseur(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $request->validate([
            'nom' => 'required|string|max:150',
            'telephone' => 'nullable|string|max:20',
            'adresse' => 'nullable|string|max:255',
            'email' => 'nullable|email|max:150',
        ]);

        $fournisseur = Fournisseur::create([
            'nom' => $request->nom,
            'telephone' => $request->telephone,
            'adresse' => $request->adresse,
            'email' => $request->email,
        ]);

        $this->addHistorique('Ajout du fournisseur: ' . $fournisseur->nom);

        return response()->json([
            'message' => 'Fournisseur ajouté avec succès',
            'fournisseur' => $fournisseur,
        ], 201);
    }

    //Ajout d'un produit
    public function addProduit(Request $request)
    {
        $user = Auth::user();

        if (!$user) {
            return response()->json([
                'message' => 'Utilisateur non identifié'
            ], 401);
        }

        $request->validate([
            'nom' => 'required|string|max:150',
            'description' => 'nullable|string',
            'prix' => 'required|numeric|min:0',
            'quantite' => 'required|integer|min:0',
            'seuil_alerte' => 'nullable|integer|min:0',
            'categorie_id' => 'nullable|exists:categories,id',
            'fournisseur_id' => 'nullable|exists:fournisseurs,id',
        ]);

        try {
            DB::beginTransaction();

            $produit = Produit::create([
                'nom' => $request->nom,
                'description' => $request->description,
                'prix' => $request->prix,
                'categorie_id' => $request->categorie_id,
                'fournisseur_id' => $request->fournisseur_id,
                'pharmacie_id' => $user->pharmacie_id,
            ]);

            // Créer le stock initial
            Stock::create([
                'produit_id' => $produit->id,
                'quantite' => $request->quantite,
                'seuil_alerte' => $request->seuil_alerte ?? 10,
            ]);

            DB::commit();
            $this->addHistorique('Ajout du produit: ' . $produit->nom);

            return response()->json([
                'message' => 'Produit ajouté avec succès',
                'produit' => $produit,
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json([
                'message' => 'Erreur lors de l\'ajout du produit: ' . $e->getMessage()
            ], 500);
        }
    }
}
