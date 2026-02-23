<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ApprovisionnementDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'approvisionnement_id',
        'produit_id',
        'quantite',
        'prix_achat',
        'total',
    ];

    protected $casts = [
        'quantite' => 'integer',
        'prix_achat' => 'decimal:2',
        'total' => 'decimal:2',
    ];

    public function approvisionnement()
    {
        return $this->belongsTo(Approvisionnement::class);
    }

    public function produit()
    {
        return $this->belongsTo(Produit::class);
    }
}
