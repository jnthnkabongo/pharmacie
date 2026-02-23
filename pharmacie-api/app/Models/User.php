<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasFactory, Notifiable, HasApiTokens;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'pharmacie_id',
        'role_id',
        'actif',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'actif' => 'boolean',
        ];
    }

    public function pharmacie()
    {
        return $this->belongsTo(Pharmacie::class);
    }

    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function ventes()
    {
        return $this->hasMany(Vente::class, 'vendeur_id');
    }

    public function approvisionnements()
    {
        return $this->hasMany(Approvisionnement::class, 'user_id');
    }

    public function mouvementsStock()
    {
        return $this->hasMany(MouvementStock::class, 'user_id');
    }

    public function journalAudits()
    {
        return $this->hasMany(JournalAudit::class, 'user_id');
    }
}
