<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Categorie extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'description',
        'pharmacie_id'
    ];

    public function produits()
    {
        return $this->hasMany(Produit::class);
    }

    public function parmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }
}
