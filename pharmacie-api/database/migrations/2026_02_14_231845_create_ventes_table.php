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
        Schema::create('ventes', function (Blueprint $table) {
            $table->id();
            $table->foreignId('pharmacie_id')->constrained();
            $table->foreignId('vendeur_id')->constrained('users');
            $table->foreignId('client_id')->nullable()->constrained()->onDelete('set null');
            $table->decimal('montant_total', 12, 2);
            $table->enum('mode_paiement', ['cash', 'mobile_money', 'carte'])->default('cash');
            $table->enum('type_vente', ['comptant', 'credit'])->default('comptant');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ventes');
    }
};
