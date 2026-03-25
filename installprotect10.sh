#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect10.sh - Admin NodesController with Ban System

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan dengan: sudo bash $0"
  exit 1
fi

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/NodesController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 [ikhsan-project] Memasang proteksi Admin NodesController dengan Ban System..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"

sudo tee "$REMOTE_PATH" << 'EOF' > /dev/null
<?php
/** 🛡️ Security by: ikhsan-project | © ikhsan-project **/

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Http\RedirectResponse;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Models\Node;
use Pterodactyl\Models\Allocation;
use Pterodactyl\Models\BannedUser;
use Pterodactyl\Http\Controllers\Controller;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Services\Nodes\NodeUpdateService;
use Pterodactyl\Services\Nodes\NodeCreationService;
use Pterodactyl\Services\Nodes\NodeDeletionService;
use Pterodactyl\Services\Allocations\AssignmentService;
use Pterodactyl\Services\Allocations\AllocationDeletionService;
use Pterodactyl\Contracts\Repository\NodeRepositoryInterface;
use Pterodactyl\Contracts\Repository\ServerRepositoryInterface;
use Carbon\Carbon;

class NodesController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected AllocationDeletionService $allocationDeletionService,
        protected AssignmentService $assignmentService,
        protected NodeCreationService $creationService,
        protected NodeDeletionService $deletionService,
        protected NodeRepositoryInterface $repository,
        protected ServerRepositoryInterface $serverRepository,
        protected NodeUpdateService $updateService,
        protected ViewFactory $view
    ) {}

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
        $user = auth()->user();
        
        if (!$user) {
            abort(403, 'Unauthorized');
        }
        
        if ($this->isUserBanned($user->id)) {
            abort(403, '🔒 Akun Anda sedang dibanned. Hubungi @Ikhsanprotject untuk bantuan.');
        }
        
        if ($user->id !== 1) {
            abort(403, "⚠️ ikhsan-project: Access denied only admin ID 1 can access nodes.");
        }
    }

    public function index(): View
    {
        $this->checkAccess();
        return $this->view->make('admin.nodes.index', ['nodes' => $this->repository->getAllWithDetails()]);
    }

    public function create(): View
    {
        $this->checkAccess();
        return $this->view->make('admin.nodes.new');
    }

    public function store(Request $request): RedirectResponse
    {
        $this->checkAccess();
        $node = $this->creationService->handle($request->normalize());
        $this->alert->info(trans('admin/node.notices.node_created'))->flash();
        return redirect()->route('admin.nodes.view.allocation', $node->id);
    }

    public function updateSettings(Request $request, Node $node): RedirectResponse
    {
        $this->checkAccess();
        
        $this->updateService->handle($node, $request->normalize(), $request->input('reset_secret') === 'on');
        $this->alert->success(trans('admin/node.notices.node_updated'))->flash();
        return redirect()->route('admin.nodes.view.settings', $node->id)->withInput();
    }

    public function delete(int|Node $node): RedirectResponse
    {
        $this->checkAccess();
        $this->deletionService->handle($node);
        $this->alert->success(trans('admin/node.notices.node_deleted'))->flash();
        return redirect()->route('admin.nodes');
    }
}
EOF

chmod 644 "$REMOTE_PATH"
chown www-data:www-data "$REMOTE_PATH"
echo "✅ [ikhsan-project] Admin NodesController dengan Ban System berhasil!"