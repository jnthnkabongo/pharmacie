<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vente extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacie_id',
        'vendeur_id',
        'client_id',
        'montant_total',
        'mode_paiement',
        'type_vente',
    ];

    protected $casts = [
        'montant_total' => 'decimal:2',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function vendeur()
    {
        return $this->belongsTo(User::class, 'vendeur_id');
    }

    public function client()
    {
        return $this->belongsTo(Client::class);
    }

    public function venteDetails()
    {
        return $this->hasMany(VenteDetail::class);
    }
}
