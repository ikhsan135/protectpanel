#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect2.sh - UserController with Ban System & Admin Overlay

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan script ini dengan sudo: sudo bash $0"
  exit 1
fi

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 [ikhsan-project] Memasang proteksi UserController dengan Ban System..."

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
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Pterodactyl\Models\BannedUser;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\JsonResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;
use Carbon\Carbon;

class UserController extends Controller
{
    use AvailableLanguages;

    public function __construct(
        protected AlertsMessageBag $alert,
        protected UserCreationService $creationService,
        protected UserDeletionService $deletionService,
        protected Translator $translator,
        protected UserUpdateService $updateService,
        protected UserRepositoryInterface $repository,
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
     * 🔒 Get ban details
     */
    private function getBanDetails($userId): ?BannedUser
    {
        return BannedUser::where('user_id', $userId)
            ->where('banned_until', '>', Carbon::now())
            ->first();
    }
    
    /**
     * 🔒 Record failed attempt and ban if needed
     */
    private function recordFailedAttempt($user): void
    {
        $attempts = (int)session()->get('ikhsan_attempts', 0);
        $attempts++;
        session()->put('ikhsan_attempts', $attempts);
        
        if ($attempts >= 3) {
            $bannedUntil = Carbon::now()->addDays(7);
            
            BannedUser::create([
                'user_id' => $user->id,
                'username' => $user->username,
                'email' => $user->email,
                'reason' => '3x gagal verifikasi password (auto-ban)',
                'failed_attempts' => 3,
                'banned_until' => $bannedUntil,
                'banned_at' => Carbon::now(),
                'banned_by' => null
            ]);
            
            session()->forget('ikhsan_attempts');
            session()->forget('ikhsan_auth_verified');
            
            throw new DisplayException('BANNED');
        }
    }
    
    /**
     * 🔒 Verify password with ban system
     */
    public function verifyPassword(Request $request): JsonResponse
    {
        $user = $request->user();
        $password = $request->input('password');
        
        // Check if already banned
        if ($this->isUserBanned($user->id)) {
            $ban = $this->getBanDetails($user->id);
            return response()->json([
                'success' => false,
                'banned' => true,
                'message' => "🔒 Akun dibanned sampai {$ban->banned_until->format('d M Y H:i')}",
                'contact' => '@Ikhsanprotject'
            ]);
        }
        
        // Jawaban yang benar: 171012khanza
        if ($password === '171012khanza') {
            session()->put('ikhsan_auth_verified', true);
            session()->put('last_activity', Carbon::now()->toDateTimeString());
            session()->forget('ikhsan_attempts');
            return response()->json(['success' => true]);
        }
        
        // Record failed attempt
        try {
            $this->recordFailedAttempt($user);
        } catch (DisplayException $e) {
            return response()->json([
                'success' => false,
                'banned' => true,
                'message' => '🔒 Anda telah dibanned selama 7 hari karena 3x gagal verifikasi! Hubungi @Ikhsanprotject'
            ]);
        }
        
        $attemptsLeft = 3 - (int)session()->get('ikhsan_attempts', 1);
        return response()->json([
            'success' => false,
            'attempts_left' => $attemptsLeft,
            'message' => "❌ Password salah! Sisa percobaan: {$attemptsLeft}"
        ]);
    }
    
    /**
     * 🔒 Check auth status with ban and session check
     */
    public function checkAuthStatus(Request $request): JsonResponse
    {
        $user = $request->user();
        
        if ($user && $this->isUserBanned($user->id)) {
            $ban = $this->getBanDetails($user->id);
            return response()->json([
                'verified' => false,
                'banned' => true,
                'banned_until' => $ban->banned_until->format('Y-m-d H:i:s'),
                'contact' => '@Ikhsanprotject'
            ]);
        }
        
        $lastActivity = session('last_activity');
        $sessionVerified = session('ikhsan_auth_verified', false);
        
        // Check inactivity (5 minutes)
        if ($sessionVerified && $lastActivity) {
            $inactiveMinutes = Carbon::now()->diffInMinutes(Carbon::parse($lastActivity));
            if ($inactiveMinutes >= 5) {
                session()->forget('ikhsan_auth_verified');
                session()->forget('last_activity');
                return response()->json([
                    'verified' => false,
                    'session_expired' => true,
                    'message' => '⏰ Session expired due to 5 minutes inactivity'
                ]);
            }
        }
        
        return response()->json([
            'verified' => $sessionVerified,
            'requires_password' => !$sessionVerified && !$this->isUserBanned($user?->id),
            'banned' => $this->isUserBanned($user?->id)
        ]);
    }
    
    /**
     * 🔒 Get banned users list (for admin overlay)
     */
    public function getBannedUsersList(Request $request): JsonResponse
    {
        if ($request->user()->id !== 1) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }
        
        $bannedUsers = BannedUser::with(['user', 'bannedBy'])
            ->where('banned_until', '>', Carbon::now())
            ->orderBy('banned_at', 'desc')
            ->get()
            ->map(function($ban) {
                $remainingHours = Carbon::now()->diffInHours($ban->banned_until);
                return [
                    'id' => $ban->id,
                    'user_id' => $ban->user_id,
                    'username' => $ban->username,
                    'email' => $ban->email,
                    'banned_at' => $ban->banned_at->format('Y-m-d H:i:s'),
                    'banned_until' => $ban->banned_until->format('Y-m-d H:i:s'),
                    'remaining_days' => ceil($remainingHours / 24),
                    'reason' => $ban->reason,
                    'banned_by' => $ban->bannedBy?->username ?? 'System'
                ];
            });
            
        return response()->json(['banned_users' => $bannedUsers]);
    }
    
    /**
     * 🔒 Unban user from admin overlay
     */
    public function unbanUser(Request $request): JsonResponse
    {
        if ($request->user()->id !== 1) {
            return response()->json(['error' => 'Unauthorized'], 403);
        }
        
        $banId = $request->input('ban_id');
        $ban = BannedUser::find($banId);
        
        if (!$ban) {
            return response()->json(['error' => 'Ban record not found'], 404);
        }
        
        $username = $ban->username;
        $ban->delete();
        
        return response()->json([
            'success' => true,
            'message' => "✅ User {$username} telah di-unban!"
        ]);
    }
    
    /**
     * 🔒 Check access with ban protection
     */
    private function checkAccess(Request $request): void
    {
        $user = $request->user();
        
        // SUPER ADMIN - full access
        if ($user && $user->id === 1) {
            return;
        }
        
        // Check if banned
        if ($this->isUserBanned($user->id)) {
            throw new DisplayException('BANNED');
        }
        
        // Check if password verified
        if (!$request->session()->has('ikhsan_auth_verified')) {
            throw new DisplayException('PASSWORD_REQUIRED');
        }
        
        // Check inactivity (5 minutes)
        $lastActivity = session('last_activity');
        if ($lastActivity && Carbon::now()->diffInMinutes(Carbon::parse($lastActivity)) >= 5) {
            session()->forget('ikhsan_auth_verified');
            session()->forget('last_activity');
            throw new DisplayException('SESSION_EXPIRED');
        }
        
        // Update last activity
        session(['last_activity' => Carbon::now()->toDateTimeString()]);
    }

    public function index(Request $request): View|RedirectResponse
    {
        try {
            $this->checkAccess($request);
        } catch (DisplayException $e) {
            if ($e->getMessage() === 'BANNED') {
                $ban = $this->getBanDetails($request->user()->id);
                return redirect()->route('auth.login')
                    ->with('error', "🔒 Akun Anda dibanned sampai {$ban->banned_until->format('d M Y H:i')}. Hubungi @Ikhsanprotject");
            }
            if ($e->getMessage() === 'SESSION_EXPIRED') {
                return redirect()->route('auth.login')
                    ->with('error', '⏰ Session berakhir karena 5 menit tidak ada aktivitas. Silakan login ulang.');
            }
            return $this->view->make('admin.ikhsan-password', [
                'menu' => 'users',
                'action' => route('admin.users.verify-password')
            ]);
        }
        
        $users = QueryBuilder::for(
            User::query()->select('users.*')
                ->selectRaw('COUNT(DISTINCT(subusers.id)) as subuser_of_count')
                ->selectRaw('COUNT(DISTINCT(servers.id)) as servers_count')
                ->leftJoin('subusers', 'subusers.user_id', '=', 'users.id')
                ->leftJoin('servers', 'servers.owner_id', '=', 'users.id')
                ->groupBy('users.id')
        )
            ->allowedFilters(['username', 'email', 'uuid'])
            ->allowedSorts(['id', 'uuid'])
            ->paginate(50);
        return $this->view->make('admin.users.index', ['users' => $users]);
    }

    public function create(Request $request): View
    {
        $this->checkAccess($request);
        return $this->view->make('admin.users.new', [
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function view(Request $request, User $user): View
    {
        $this->checkAccess($request);
        return $this->view->make('admin.users.view', [
            'user' => $user,
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    public function delete(Request $request, User $user): RedirectResponse
    {
        $this->checkAccess($request);
        
        if ($request->user()->id !== 1) {
            throw new DisplayException("❌ Hanya admin ID 1 yang dapat menghapus user lain! ©ikhsan-project");
        }
        if ($request->user()->id === $user->id) {
            throw new DisplayException($this->translator->get('admin/user.exceptions.user_has_servers'));
        }
        $this->deletionService->handle($user);
        return redirect()->route('admin.users');
    }

    public function store(NewUserFormRequest $request): RedirectResponse
    {
        $this->checkAccess($request);
        $user = $this->creationService->handle($request->normalize());
        $this->alert->success($this->translator->get('admin/user.notices.account_created'))->flash();
        return redirect()->route('admin.users.view', $user->id);
    }

    public function update(UserFormRequest $request, User $user): RedirectResponse
    {
        $this->checkAccess($request);
        
        $restrictedFields = ['email', 'first_name', 'last_name', 'password'];
        foreach ($restrictedFields as $field) {
            if ($request->filled($field) && $request->user()->id !== 1) {
                throw new DisplayException("⚠️ Data hanya bisa diubah oleh admin ID 1. ©ikhsan-project");
            }
        }
        if ($user->root_admin && $request->user()->id !== 1) {
            throw new DisplayException("🚫 Tidak dapat menurunkan hak admin pengguna ini. Hanya ID 1 yang memiliki izin. ©ikhsan-project");
        }
        $this->updateService
            ->setUserLevel(User::USER_LEVEL_ADMIN)
            ->handle($user, $request->normalize());
        $this->alert->success(trans('admin/user.notices.account_updated'))->flash();
        return redirect()->route('admin.users.view', $user->id);
    }

    public function json(Request $request): Model|Collection
    {
        $this->checkAccess($request);
        $users = QueryBuilder::for(User::query())->allowedFilters(['email'])->paginate(25);
        if ($request->query('user_id')) {
            $user = User::query()->findOrFail($request->input('user_id'));
            $user->md5 = md5(strtolower($user->email));
            return $user;
        }
        return $users->map(function ($item) {
            $item->md5 = md5(strtolower($item->email));
            return $item;
        });
    }
}
EOF

chmod 644 "$REMOTE_PATH"
chown www-data:www-data "$REMOTE_PATH"
echo "✅ [ikhsan-project] Proteksi UserController dengan Ban System berhasil dipasang!"