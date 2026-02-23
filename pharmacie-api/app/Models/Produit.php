<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Produit extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacie_id',
        'categorie_id',
        'fournisseur_id',
        'nom',
        'description',
        'code_barre',
        'prix_achat',
        'prix_vente',   
        'date_expiration'
    ];

    protected $casts = [
        'prix_achat' => 'decimal:2',
        'prix_vente' => 'decimal:2',
        'date_expiration' => 'date',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function categorie()
    {
        return $this->belongsTo(Categorie::class);
    }

    public function fournisseur()
    {
        return $this->belongsTo(Fournisseur::class);
    }

    public function stock()
    {
        return $this->hasOne(Stock::class);
    }

    public function venteDetails()
    {
        return $this->hasMany(VenteDetail::class);
    }

    public function approvisionnementDetails()
    {
        return $this->hasMany(ApprovisionnementDetail::class);
    }

    public function mouvementsStock()
    {
        return $this->hasMany(MouvementStock::class);
    }
}
