#!/bin/bash
# 🛡️ ikhsan-project - Create Migration for Banned Users

MIGRATION_PATH="/var/www/pterodactyl/database/migrations/$(date +%Y_%m_%d_%H%M%S)_create_banned_users_table.php"

sudo tee "$MIGRATION_PATH" << 'EOF' > /dev/null
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('banned_users', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id');
            $table->string('username');
            $table->string('email');
            $table->text('reason')->nullable();
            $table->integer('failed_attempts')->default(3);
            $table->timestamp('banned_until');
            $table->timestamp('banned_at');
            $table->unsignedBigInteger('banned_by')->nullable();
            $table->timestamps();
            
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('banned_by')->references('id')->on('users')->onDelete('set null');
            $table->index(['user_id', 'banned_until']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('banned_users');
    }
};
EOF

echo "✅ Migration created! Run: php artisan migrate"