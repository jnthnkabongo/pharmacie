<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

// Routes publiques
// Route::get('/', function () {
//     return response()->json(['message' => 'API Pharmacie']);
// });

// Routes d'authentification
Route::post('/register', [ApiController::class, 'register']);
Route::get('liste-pharmacie-connexion', [ApiController::class, 'listePharmacie']);
Route::post('/login', [ApiController::class, 'login']);
Route::post('/create-user', [ApiController::class, 'createUser']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('dashboard', [ApiController::class, 'dashboard']);

    // Routes historiques
    Route::get('historique', [ApiController::class, 'getHistoriques']);
    
    // Routes stocks
    Route::get('/liste-stock', [ApiController::class, 'getStock']);
    
    // Routes des utilisateurs
    Route::get('users', [ApiController::class, 'getUsers']);

    // Routes ventes
    Route::get('/liste-ventes', [ApiController::class, 'getVentes']);
    Route::post('/add-vente', [ApiController::class, 'addVente']);
    
    // Routes approvisionnements
    Route::get('/liste-approvisionnements', [ApiController::class, 'getApprovisionnements']);
    Route::post('/add-approvisionnement', [ApiController::class, 'addApprovisionnement']);
    Route::delete('/delete-approvisionnement/{id}', [ApiController::class, 'deleteApprovisionnement']);

    // Routes fournisseurs
    Route::get('/liste-fournisseurs', [ApiController::class, 'getFournisseurs']);
    Route::post('/add-fournisseur', [ApiController::class, 'addFournisseur']);
    
    // Routes produits
    Route::get('liste-produits', [ApiController::class, 'getProduits']);
    Route::post('/add-produit', [ApiController::class, 'addProduit']);
    Route::post('/add-multiple-produits', [ApiController::class, 'addMultipleProduits']);
    Route::put('/update-produit/{id}', [ApiController::class, 'updateProduit']);
    Route::delete('/delete-produit/{id}', [ApiController::class, 'deleteProduit']);

    // Routes categories
    Route::get('/liste-categories', [ApiController::class, 'getCategories']);
    Route::post('/add-categorie', [ApiController::class, 'addCategorie']);
    
    // Routes seuil
    Route::get('/seuil-atteint', [ApiController::class, 'seuil_atteint']);
    Route::get('/stock-expire', [ApiController::class, 'stock_expires']);
    Route::get('seuil-inferieur', [ApiController::class, 'seuil_inferieur']);
});

