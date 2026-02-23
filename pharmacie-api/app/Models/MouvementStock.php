<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MouvementStock extends Model
{
    use HasFactory;

    protected $table = 'mouvements_stock';

    protected $fillable = [
        'pharmacie_id',
        'produit_id',
        'type',
        'quantite',
        'reference',
        'user_id',
    ];

    protected $casts = [
        'quantite' => 'integer',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function produit()
    {
        return $this->belongsTo(Produit::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
