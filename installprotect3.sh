#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect3.sh - LocationController with Ban System

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan script ini dengan sudo: sudo bash $0"
  exit 1
fi

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 [ikhsan-project] Memasang proteksi LocationController dengan Ban System..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"
chmod 755 "$(dirname "$REMOTE_PATH")"

sudo tee "$REMOTE_PATH" << 'EOF' > /dev/null
<?php
/** 🛡️ Security by: ikhsan-project | © ikhsan-project **/

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Models\Location;
use Pterodactyl\Models\BannedUser;
use Prologue\Alerts\AlertsMessageBag;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Http\Requests\Admin\LocationFormRequest;
use Pterodactyl\Services\Locations\LocationUpdateService;
use Pterodactyl\Services\Locations\LocationCreationService;
use Pterodactyl\Services\Locations\LocationDeletionService;
use Pterodactyl\Contracts\Repository\LocationRepositoryInterface;
use Carbon\Carbon;

class LocationController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected LocationCreationService $creationService,
        protected LocationDeletionService $deletionService,
        protected LocationRepositoryInterface $repository,
        protected LocationUpdateService $updateService,
        protected ViewFactory $view
    ) {
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
            abort(403, 'ikhsan-project - Akses ditolak');
        }
    }

    public function index(): View
    {
        $this->checkAccess();
        return $this->view->make('admin.locations.index', [
            'locations' => $this->repository->getAllWithDetails(),
        ]);
    }

    public function view(int $id): View
    {
        $this->checkAccess();
        return $this->view->make('admin.locations.view', [
            'location' => $this->repository->getWithNodes($id),
        ]);
    }

    public function create(LocationFormRequest $request): RedirectResponse
    {
        $this->checkAccess();
        $location = $this->creationService->handle($request->normalize());
        $this->alert->success('Location was created successfully.')->flash();
        return redirect()->route('admin.locations.view', $location->id);
    }

    public function update(LocationFormRequest $request, Location $location): RedirectResponse
    {
        $this->checkAccess();
        if ($request->input('action') === 'delete') {
            return $this->delete($location);
        }
        $this->updateService->handle($location->id, $request->normalize());
        $this->alert->success('Location was updated successfully.')->flash();
        return redirect()->route('admin.locations.view', $location->id);
    }

    public function delete(Location $location): RedirectResponse
    {
        $this->checkAccess();
        try {
            $this->deletionService->handle($location->id);
            return redirect()->route('admin.locations');
        } catch (DisplayException $ex) {
            $this->alert->danger($ex->getMessage())->flash();
        }
        return redirect()->route('admin.locations.view', $location->id);
    }
}
EOF

chmod 644 "$REMOTE_PATH"
chown www-data:www-data "$REMOTE_PATH"
echo "✅ [ikhsan-project] Proteksi LocationController dengan Ban System berhasil dipasang!"