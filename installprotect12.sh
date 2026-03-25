#!/bin/bash
# 🛡️ ikhsan-project - BannedUser Model

MODEL_PATH="/var/www/pterodactyl/app/Models/BannedUser.php"

sudo tee "$MODEL_PATH" << 'EOF' > /dev/null
<?php
/** 🛡️ ikhsan-project - Banned User Model **/

namespace Pterodactyl\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class BannedUser extends Model
{
    protected $table = 'banned_users';
    
    protected $fillable = [
        'user_id',
        'username',
        'email',
        'reason',
        'failed_attempts',
        'banned_until',
        'banned_at',
        'banned_by'
    ];
    
    protected $casts = [
        'banned_until' => 'datetime',
        'banned_at' => 'datetime',
        'failed_attempts' => 'integer'
    ];
    
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }
    
    public function bannedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'banned_by');
    }
    
    public function isActive(): bool
    {
        return $this->banned_until->isFuture();
    }
}
EOF

echo "✅ BannedUser Model created!"