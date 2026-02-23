<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Approvisionnement extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacie_id',
        'fournisseur_id',
        'user_id',
        'montant_total',
    ];

    protected $casts = [
        'montant_total' => 'decimal:2',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function fournisseur()
    {
        return $this->belongsTo(Fournisseur::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function approvisionnementDetails()
    {
        return $this->hasMany(ApprovisionnementDetail::class);
    }
}
