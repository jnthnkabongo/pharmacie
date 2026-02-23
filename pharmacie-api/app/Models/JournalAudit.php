<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JournalAudit extends Model
{
    use HasFactory;

    protected $fillable = [
        'pharmacie_id',
        'user_id',
        'action',
        'table_concernee',
        'enregistrement_id',
        'ancienne_valeur',
        'nouvelle_valeur',
    ];

    protected $casts = [
        'enregistrement_id' => 'integer',
    ];

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
