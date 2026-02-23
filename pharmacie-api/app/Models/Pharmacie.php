<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Pharmacie extends Model
{
    use HasFactory;

    protected $fillable = [
        'nom',
        'telephone',
        'adresse',
    ];

    public function users()
    {
        return $this->hasMany(User::class);
    }

    public function produits()
    {
        return $this->hasMany(Produit::class);
    }

    public function clients()
    {
        return $this->hasMany(Client::class);
    }

    public function ventes()
    {
        return $this->hasMany(Vente::class);
    }

    public function approvisionnements()
    {
        return $this->hasMany(Approvisionnement::class);
    }

    public function mouvementsStock()
    {
        return $this->hasMany(MouvementStock::class);
    }

    public function journalAudits()
    {
        return $this->hasMany(JournalAudit::class);
    }
}
