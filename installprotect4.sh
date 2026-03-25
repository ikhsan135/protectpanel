#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect4.sh - NodeController with Ban System

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan script ini dengan sudo: sudo bash $0"
  exit 1
fi

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 [ikhsan-project] Memasang proteksi NodeController dengan Ban System..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

sudo tee "$REMOTE_PATH" << 'EOF' > /dev/null
<?php
/** 🛡️ Security by: ikhsan-project | © ikhsan-project **/

namespace Pterodactyl\Http\Controllers\Admin\Nodes;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\Node;
use Pterodactyl\Models\BannedUser;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\View\Factory as ViewFactory;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class NodeController extends Controller
{
    public function __construct(private ViewFactory $view)
    {
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
    
    /**
     * 🔒 Check access with ban protection
     */
    private function checkAccess(): void
    {
        $user = Auth::user();
        
        if (!$user) {
            abort(403, 'Unauthorized');
        }
        
        if ($this->isUserBanned($user->id)) {
            abort(403, '🔒 Akun Anda sedang dibanned. Hubungi @Ikhsanprotject untuk bantuan.');
        }
        
        if ($user->id !== 1) {
            abort(403, '🚫 Akses ditolak! Hanya admin ID 1 yang dapat membuka menu Nodes. ©ikhsan-project');
        }
    }

    public function index(Request $request): View
    {
        $this->checkAccess();

        $nodes = QueryBuilder::for(
            Node::query()->with('location')->withCount('servers')
        )
            ->allowedFilters(['uuid', 'name'])
            ->allowedSorts(['id'])
            ->paginate(25);

        return $this->view->make('admin.nodes.index', ['nodes' => $nodes]);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
chown www-data:www-data "$REMOTE_PATH"
echo "✅ [ikhsan-project] Proteksi NodeController dengan Ban System berhasil dipasang!"