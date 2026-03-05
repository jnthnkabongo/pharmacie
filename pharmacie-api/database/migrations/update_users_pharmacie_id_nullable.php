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
        Schema::table('users', function (Blueprint $table) {
            // Rendre pharmacie_id non nullable
            $table->foreignId('pharmacie_id')->nullable(false)->change();
            
            // Ajouter une contrainte de clé étrangère si elle n'existe pas
            $table->foreign('pharmacie_id')->references('id')->on('pharmacies')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropForeign(['pharmacie_id']);
            $table->foreignId('pharmacie_id')->nullable()->change();
        });
    }
};
