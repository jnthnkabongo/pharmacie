<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class historique extends Model
{
    protected $fillable = [
        'user_id',
        'pharmacie_id',
        'action',
        'description',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
    
    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }
}
