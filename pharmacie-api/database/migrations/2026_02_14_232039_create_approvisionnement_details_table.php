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
        Schema::create('approvisionnement_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('approvisionnement_id')->constrained()->onDelete('cascade');
            $table->foreignId('produit_id')->constrained();
            $table->integer('quantite');
            $table->decimal('prix_achat', 10, 2)->nullable();
            $table->decimal('total', 12, 2)->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('approvisionnement_details');
    }
};
