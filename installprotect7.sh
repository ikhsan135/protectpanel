#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect7.sh - Client ServerController with Ban Check

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan dengan: sudo bash $0"
  exit 1
fi

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 [ikhsan-project] Memasang proteksi Client ServerController dengan Ban System..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"

sudo tee "$REMOTE_PATH" << 'EOF' > /dev/null
<?php
/** 🛡️ Security by: ikhsan-project | © ikhsan-project **/

namespace Pterodactyl\Http\Controllers\Api\Client\Servers;

use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Server;
use Pterodactyl\Models\BannedUser;
use Pterodactyl\Transformers\Api\Client\ServerTransformer;
use Pterodactyl\Services\Servers\GetUserPermissionsService;
use Pterodactyl\Http\Controllers\Api\Client\ClientApiController;
use Pterodactyl\Http\Requests\Api\Client\Servers\GetServerRequest;
use Carbon\Carbon;

class ServerController extends ClientApiController
{
    public function __construct(private GetUserPermissionsService $permissionsService)
    {
        parent::__construct();
    }

    /**
     * 🔒 Check if user is banned
     */
    private function isUserBanned($userId): bool
    {
        return BannedUser::where('user_id', $userId)
            ->where('banned_until', '>', Carbon::now())
            ->exists();
    }

    public function index(GetServerRequest $request, Server $server): array
    {
        $authUser = Auth::user();
        
        // 🔒 Cek apakah user dibanned
        if ($authUser && $this->isUserBanned($authUser->id)) {
            abort(403, '🔒 Akun Anda sedang dibanned. Hubungi @Ikhsanprotject untuk bantuan.');
        }
        
        if ($authUser->id !== 1 && (int) $server->owner_id !== (int) $authUser->id) {
            abort(403, 'ikhsan-project • Akses Di Tolak❌. Hanya Bisa Melihat Server Sendiri.');
        }

        return $this->fractal->item($server)
            ->transformWith($this->getTransformer(ServerTransformer::class))
            ->addMeta([
                'is_server_owner' => $request->user()->id === $server->owner_id,
                'user_permissions' => $this->permissionsService->handle($server, $request->user()),
            ])
            ->toArray();
    }
}
EOF

chmod 644 "$REMOTE_PATH"
chown www-data:www-data "$REMOTE_PATH"
echo "✅ [ikhsan-project] Client Server Controller dengan Ban System berhasil!"