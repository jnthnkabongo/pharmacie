<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('produits', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacie_id')->constrained()->onDelete('cascade');
            $table->foreignId('categorie_id')->nullable()->constrained()->onDelete('set null');
            $table->foreignId('fournisseur_id')->nullable()->constrained()->onDelete('set null');
            $table->string('nom', 150);
            $table->text('description')->nullable();
            $table->string('code_barre', 100)->nullable();
            $table->decimal('prix_achat', 10, 2)->nullable();
            $table->decimal('prix_vente', 10, 2)->nullable();
            $table->date('date_expiration')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('produits');
    }
};
