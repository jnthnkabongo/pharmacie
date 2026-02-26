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
Route::get('/', function () {
    return response()->json(['message' => 'API Pharmacie']);
});

// Routes d'authentification
Route::post('/register', [ApiController::class, 'register']);
Route::post('/login', [ApiController::class, 'login']);
Route::post('/create-user', [ApiController::class, 'createUser']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('historique', [ApiController::class, 'getHistoriques']);
    Route::get('/liste-stock', [ApiController::class, 'getStock']);
    Route::get('liste-produits', [ApiController::class, 'getProduits']);
    Route::get('/liste-ventes', [ApiController::class, 'getVentes']);
    Route::get('users', [ApiController::class, 'getUsers']);
    Route::post('/add-vente', [ApiController::class, 'addVente']);
    
    // Routes approvisionnement
    Route::get('/liste-approvisionnements', [ApiController::class, 'getApprovisionnements']);
    Route::get('/liste-fournisseurs', [ApiController::class, 'getFournisseurs']);
    Route::post('/add-approvisionnement', [ApiController::class, 'addApprovisionnement']);
    Route::post('/add-fournisseur', [ApiController::class, 'addFournisseur']);
    Route::delete('/delete-approvisionnement/{id}', [ApiController::class, 'deleteApprovisionnement']);
});

