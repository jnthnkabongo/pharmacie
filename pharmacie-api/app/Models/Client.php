<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Client extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacie_id',
        'nom',
        'telephone',
        'adresse',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function ventes()
    {
        return $this->hasMany(Vente::class);
    }
}
