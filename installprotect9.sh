#!/bin/bash
# 🛡️ Watermark: ikhsan-project
# File: installprotect9.sh - Core Blade Template with Admin Ban Overlay & Neon UI

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Harap jalankan dengan: sudo bash $0"
  exit 1
fi

TARGET_FILE="/var/www/pterodactyl/resources/views/templates/base/core.blade.php"
BACKUP_FILE="${TARGET_FILE}.bak_$(date -u +"%Y-%m-%d-%H-%M-%S")"

echo "🚀 [ikhsan-project] Memasang Core Template dengan Admin Ban Overlay & Neon UI..."

if [ -f "$TARGET_FILE" ]; then
  cp "$TARGET_FILE" "$BACKUP_FILE"
fi

sudo tee "$TARGET_FILE" << 'EOF' > /dev/null
@extends('templates/wrapper', [
    'css' => ['body' => 'bg-neutral-900'],
])

@section('container')
    <div id="modal-portal"></div>
    <div id="app"></div>

    <style>
        /* 🎨 DARK NEON GLOW THEME - ikhsan-project */
        :root {
            --neon-cyan: #00f2ff;
            --neon-pink: #ff0055;
            --neon-green: #00ff66;
            --neon-glow-cyan: 0 0 10px #00f2ff, 0 0 20px #00f2ff;
            --neon-glow-pink: 0 0 10px #ff0055, 0 0 20px #ff0055;
            --neon-glow-green: 0 0 10px #00ff66, 0 0 20px #00ff66;
            --bg-dark: #0a0a0f;
            --bg-card: rgba(15, 15, 25, 0.85);
            --glass-border: rgba(0, 242, 255, 0.2);
        }
        
        body {
            background: var(--bg-dark);
            font-family: 'Courier New', 'Fira Code', monospace;
        }
        
        /* Glassmorphism Card Effect */
        .glass-card {
            background: var(--bg-card);
            backdrop-filter: blur(12px);
            border: 1px solid var(--glass-border);
            border-radius: 16px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }
        
        /* Password Overlay - Dark Neon */
        .password-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.98);
            backdrop-filter: blur(20px);
            z-index: 10000;
            display: flex;
            justify-content: center;
            align-items: center;
            animation: fadeIn 0.3s ease;
        }
        
        .password-modal {
            background: linear-gradient(135deg, rgba(10, 10, 20, 0.98), rgba(5, 5, 15, 0.98));
            border: 2px solid var(--neon-cyan);
            border-radius: 24px;
            padding: 40px;
            max-width: 450px;
            width: 90%;
            text-align: center;
            box-shadow: var(--neon-glow-cyan);
            animation: slideUp 0.4s ease;
        }
        
        .password-modal h2 {
            color: var(--neon-cyan);
            font-size: 24px;
            margin-bottom: 20px;
            text-shadow: var(--neon-glow-cyan);
            letter-spacing: 2px;
        }
        
        .password-modal p {
            color: #aaa;
            font-size: 14px;
            margin-bottom: 25px;
        }
        
        .password-input {
            width: 100%;
            padding: 14px 18px;
            background: rgba(0, 0, 0, 0.6);
            border: 1px solid var(--neon-cyan);
            border-radius: 12px;
            color: var(--neon-cyan);
            font-family: monospace;
            font-size: 16px;
            text-align: center;
            letter-spacing: 2px;
            outline: none;
            transition: all 0.3s;
        }
        
        .password-input:focus {
            box-shadow: var(--neon-glow-cyan);
            border-color: var(--neon-cyan);
        }
        
        .password-btn {
            margin-top: 20px;
            padding: 12px 28px;
            background: linear-gradient(135deg, var(--neon-cyan), #0099cc);
            border: none;
            border-radius: 40px;
            color: #000;
            font-weight: bold;
            font-family: monospace;
            cursor: pointer;
            transition: all 0.3s;
            font-size: 16px;
        }
        
        .password-btn:hover {
            transform: scale(1.02);
            box-shadow: var(--neon-glow-cyan);
        }
        
        .error-message {
            color: var(--neon-pink);
            margin-top: 15px;
            font-size: 13px;
            text-shadow: var(--neon-glow-pink);
        }
        
        /* Toast Rules - Neon Style */
        #rules-toast {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: rgba(10, 10, 20, 0.95);
            backdrop-filter: blur(12px);
            border-left: 4px solid var(--neon-cyan);
            border-radius: 12px;
            padding: 16px 20px;
            max-width: 350px;
            z-index: 9999;
            font-family: monospace;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
            transition: all 0.4s ease;
        }
        
        .rules-header {
            color: var(--neon-cyan);
            font-weight: bold;
            margin-bottom: 12px;
            font-size: 14px;
            text-shadow: var(--neon-glow-cyan);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .rules-list {
            margin: 0;
            padding-left: 20px;
            color: #ccc;
            font-size: 11px;
            line-height: 1.6;
        }
        
        .rules-list li {
            margin: 5px 0;
        }
        
        .close-toast {
            cursor: pointer;
            color: var(--neon-pink);
            font-weight: bold;
            font-size: 16px;
        }
        
        .toast-trigger {
            position: fixed;
            bottom: 20px;
            right: 20px;
            background: linear-gradient(135deg, var(--neon-pink), #aa0044);
            color: white;
            padding: 10px 16px;
            border-radius: 40px;
            cursor: pointer;
            font-family: monospace;
            font-size: 12px;
            font-weight: bold;
            z-index: 9998;
            box-shadow: var(--neon-glow-pink);
            transition: all 0.3s;
        }
        
        .toast-trigger:hover {
            transform: scale(1.05);
        }
        
        /* Admin Ban Overlay - Only for ID 1 */
        .admin-ban-overlay {
            position: fixed;
            bottom: 20px;
            left: 20px;
            z-index: 10001;
        }
        
        .admin-ban-btn {
            background: linear-gradient(135deg, var(--neon-pink), #aa0044);
            border: none;
            border-radius: 40px;
            padding: 12px 20px;
            color: white;
            font-family: monospace;
            font-weight: bold;
            cursor: pointer;
            box-shadow: var(--neon-glow-pink);
            transition: all 0.3s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .admin-ban-btn:hover {
            transform: scale(1.05);
        }
        
        .ban-modal {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: 90%;
            max-width: 800px;
            max-height: 80vh;
            background: linear-gradient(135deg, #0a0a1a, #050510);
            border: 2px solid var(--neon-pink);
            border-radius: 20px;
            z-index: 10002;
            overflow: hidden;
            box-shadow: var(--neon-glow-pink);
            animation: slideUp 0.3s ease;
        }
        
        .ban-modal-header {
            background: rgba(0, 0, 0, 0.8);
            padding: 20px;
            border-bottom: 1px solid var(--neon-pink);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .ban-modal-header h3 {
            color: var(--neon-pink);
            margin: 0;
            text-shadow: var(--neon-glow-pink);
        }
        
        .ban-modal-body {
            padding: 20px;
            overflow-y: auto;
            max-height: 60vh;
        }
        
        .ban-table {
            width: 100%;
            border-collapse: collapse;
            color: #ccc;
            font-size: 12px;
        }
        
        .ban-table th {
            text-align: left;
            padding: 12px;
            background: rgba(0, 242, 255, 0.1);
            color: var(--neon-cyan);
            border-bottom: 1px solid var(--neon-cyan);
        }
        
        .ban-table td {
            padding: 10px 12px;
            border-bottom: 1px solid rgba(0, 242, 255, 0.2);
        }
        
        .unban-btn {
            background: linear-gradient(135deg, var(--neon-green), #00aa44);
            border: none;
            border-radius: 20px;
            padding: 5px 12px;
            color: black;
            font-weight: bold;
            cursor: pointer;
            font-size: 11px;
        }
        
        .close-modal {
            background: none;
            border: none;
            color: var(--neon-pink);
            font-size: 24px;
            cursor: pointer;
        }
        
        .modal-backdrop {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.8);
            z-index: 10001;
        }
        
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        
        @keyframes slideUp {
            from { transform: translate(-50%, -40%); opacity: 0; }
            to { transform: translate(-50%, -50%); opacity: 1; }
        }
    </style>

    <script>
    /** 🛡️ ikhsan-project - Complete Security System with Admin Ban Overlay **/
    
    let activityInterval = null;
    let sessionTimeout = null;
    
    (async function() {
        const userId = @json(auth()->user()->id ?? null);
        const isAdmin = userId === 1;
        
        // Function to check if user is banned
        async function checkBanStatus() {
            try {
                const response = await fetch('/admin/check-auth-status', {
                    headers: { 'X-Requested-With': 'XMLHttpRequest' }
                });
                const data = await response.json();
                
                if (data.banned) {
                    window.location.href = '/auth/login';
                    return true;
                }
                return false;
            } catch(e) {
                return false;
            }
        }
        
        // Activity tracker
        function startActivityTracker() {
            if (activityInterval) clearInterval(activityInterval);
            
            let lastActivity = Date.now();
            
            const updateActivity = () => {
                lastActivity = Date.now();
            };
            
            document.addEventListener('click', updateActivity);
            document.addEventListener('keypress', updateActivity);
            document.addEventListener('mousemove', updateActivity);
            
            activityInterval = setInterval(async () => {
                const inactiveTime = (Date.now() - lastActivity) / 1000 / 60;
                
                if (inactiveTime >= 5) {
                    const response = await fetch('/admin/check-auth-status', {
                        headers: { 'X-Requested-With': 'XMLHttpRequest' }
                    });
                    const data = await response.json();
                    
                    if (data.session_expired || !data.verified) {
                        if (window.location.pathname.includes('/admin/')) {
                            showPasswordOverlay(true);
                        }
                    }
                }
            }, 30000);
        }
        
        // Show password overlay
        async function showPasswordOverlay(isExpired = false) {
            const isBanned = await checkBanStatus();
            if (isBanned) return;
            
            const existingOverlay = document.querySelector('.password-overlay');
            if (existingOverlay) return;
            
            const overlay = document.createElement('div');
            overlay.className = 'password-overlay';
            overlay.innerHTML = `
                <div class="password-modal">
                    <h2>🔐 ${isExpired ? 'SESSION EXPIRED' : 'SECURE ACCESS'}</h2>
                    <p>© ikhsan-project | ${isExpired ? 'Session berakhir karena 5 menit tidak aktif' : 'Verifikasi diperlukan'}</p>
                    <p style="color: #ff0055; font-size: 12px;">"kapan ikhsan lahir, dan siapa crush nya?"</p>
                    <input type="password" class="password-input" id="ikhsan-password" placeholder="Masukkan jawaban..." autocomplete="off">
                    <button class="password-btn" id="submit-password">VERIFY →</button>
                    <div id="password-error" class="error-message"></div>
                </div>
            `;
            
            document.body.appendChild(overlay);
            
            const input = document.getElementById('ikhsan-password');
            const submitBtn = document.getElementById('submit-password');
            const errorDiv = document.getElementById('password-error');
            
            const verify = async () => {
                const password = input.value.trim();
                if (!password) {
                    errorDiv.textContent = '❌ Masukkan jawaban terlebih dahulu!';
                    return;
                }
                
                try {
                    const response = await fetch('/admin/verify-password', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                            'X-Requested-With': 'XMLHttpRequest'
                        },
                        body: JSON.stringify({ password: password })
                    });
                    
                    const result = await response.json();
                    
                    if (result.success) {
                        overlay.remove();
                        location.reload();
                    } else if (result.banned) {
                        errorDiv.textContent = result.message || '🔒 Anda telah dibanned! Hubungi @Ikhsanprotject';
                        setTimeout(() => {
                            window.location.href = '/auth/login';
                        }, 3000);
                    } else {
                        errorDiv.textContent = result.message || `❌ Jawaban salah! Sisa percobaan: ${result.attempts_left}`;
                        input.value = '';
                        input.focus();
                        
                        if (result.attempts_left === 1) {
                            errorDiv.style.color = '#ff0055';
                            errorDiv.style.textShadow = '0 0 10px #ff0055';
                        }
                    }
                } catch (err) {
                    errorDiv.textContent = '❌ Error sistem. Coba lagi.';
                }
            };
            
            submitBtn.addEventListener('click', verify);
            input.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') verify();
            });
            
            input.focus();
        }
        
        // Admin Ban Management Overlay (only for ID 1)
        async function initAdminBanOverlay() {
            if (!isAdmin) return;
            
            const adminBtn = document.createElement('div');
            adminBtn.className = 'admin-ban-overlay';
            adminBtn.innerHTML = `
                <button class="admin-ban-btn" id="admin-ban-btn">
                    🔒 BAN MANAGEMENT
                </button>
            `;
            document.body.appendChild(adminBtn);
            
            let modalOpen = false;
            
            const loadBanList = async () => {
                try {
                    const response = await fetch('/admin/get-banned-users', {
                        headers: { 'X-Requested-With': 'XMLHttpRequest' }
                    });
                    const data = await response.json();
                    
                    if (data.banned_users && data.banned_users.length > 0) {
                        return data.banned_users;
                    }
                    return [];
                } catch(e) {
                    return [];
                }
            };
            
            const unbanUser = async (banId, username) => {
                try {
                    const response = await fetch('/admin/unban-user', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/json',
                            'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '',
                            'X-Requested-With': 'XMLHttpRequest'
                        },
                        body: JSON.stringify({ ban_id: banId })
                    });
                    
                    const result = await response.json();
                    if (result.success) {
                        alert(result.message);
                        closeModal();
                        openModal();
                    } else {
                        alert('Gagal unban: ' + (result.error || 'Unknown error'));
                    }
                } catch(e) {
                    alert('Error: ' + e.message);
                }
            };
            
            const openModal = async () => {
                if (modalOpen) return;
                modalOpen = true;
                
                const bannedUsers = await loadBanList();
                
                const backdrop = document.createElement('div');
                backdrop.className = 'modal-backdrop';
                
                const modal = document.createElement('div');
                modal.className = 'ban-modal';
                modal.innerHTML = `
                    <div class="ban-modal-header">
                        <h3>🔒 BANNED USERS MANAGEMENT</h3>
                        <button class="close-modal" id="close-ban-modal">✕</button>
                    </div>
                    <div class="ban-modal-body">
                        ${bannedUsers.length === 0 ? 
                            '<p style="text-align:center; color:#00ff66;">✅ Tidak ada user yang sedang dibanned</p>' :
                            `
                            <table class="ban-table">
                                <thead>
                                    <tr>
                                        <th>Username</th>
                                        <th>Email</th>
                                        <th>Banned At</th>
                                        <th>Banned Until</th>
                                        <th>Remaining</th>
                                        <th>Reason</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    ${bannedUsers.map(ban => `
                                        <tr>
                                            <td><span style="color:#ff0055;">${escapeHtml(ban.username)}</span></td>
                                            <td>${escapeHtml(ban.email)}</td>
                                            <td>${ban.banned_at}</td>
                                            <td>${ban.banned_until}</td>
                                            <td><span style="color:#00ff66;">${ban.remaining_days} days</span></td>
                                            <td style="max-width:150px;">${escapeHtml(ban.reason || '-')}</td>
                                            <td><button class="unban-btn" data-id="${ban.id}" data-username="${escapeHtml(ban.username)}">UNBAN</button></td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                            `
                        }
                        <div style="margin-top:20px; text-align:center; font-size:11px; color:#666; border-top:1px solid #333; padding-top:15px;">
                            📞 Hubungi @Ikhsanprotject untuk bantuan lebih lanjut
                        </div>
                    </div>
                `;
                
                document.body.appendChild(backdrop);
                document.body.appendChild(modal);
                
                document.getElementById('close-ban-modal').addEventListener('click', closeModal);
                backdrop.addEventListener('click', closeModal);
                
                document.querySelectorAll('.unban-btn').forEach(btn => {
                    btn.addEventListener('click', () => {
                        const banId = btn.dataset.id;
                        const username = btn.dataset.username;
                        if (confirm(`Unban user ${username}?`)) {
                            unbanUser(banId, username);
                        }
                    });
                });
            };
            
            const closeModal = () => {
                modalOpen = false;
                const modal = document.querySelector('.ban-modal');
                const backdrop = document.querySelector('.modal-backdrop');
                if (modal) modal.remove();
                if (backdrop) backdrop.remove();
            };
            
            document.getElementById('admin-ban-btn').addEventListener('click', openModal);
        }
        
        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }
        
        // Rules Toast System
        function initRulesToast() {
            const rules = [
                "🚫 Anti-DDoS: Dilarang keras menjalankan script DDoS!",
                "⚖️ Legalitas: Dilarang aktivitas ilegal/hacking!",
                "🎮 Game: Dilarang membuat server Minecraft!",
                "🛡️ Security: Dilarang serangan DDoS terhadap panel/node!",
                "💻 Stability: Dilarang membuat VPS overload!"
            ];
            
            const username = @json(auth()->user()->name ?? 'User');
            
            const toast = document.createElement("div");
            toast.id = "rules-toast";
            toast.innerHTML = `
                <div class="rules-header">
                    <span>📜 RULES & REGULATIONS</span>
                    <span class="close-toast" id="close-rules-toast">✕</span>
                </div>
                <ul class="rules-list">
                    ${rules.map(r => `<li>${r}</li>`).join('')}
                </ul>
                <div style="margin-top: 12px; font-size: 10px; color: #666; border-top: 1px solid rgba(0,242,255,0.2); padding-top: 8px;">
                    ⚡ Woi ${username}, Jangan Langgar Rules! Hubungi @Ikhsanprotject jika ada kendala
                </div>
            `;
            
            const trigger = document.createElement("div");
            trigger.className = "toast-trigger";
            trigger.innerHTML = "📜 RULES";
            
            document.body.appendChild(toast);
            document.body.appendChild(trigger);
            
            let autoCloseTimeout;
            
            const hideToast = () => {
                toast.style.opacity = "0";
                toast.style.transform = "translateX(100%)";
                setTimeout(() => {
                    toast.style.display = "none";
                    trigger.style.display = "flex";
                }, 400);
                clearTimeout(autoCloseTimeout);
            };
            
            const showToast = () => {
                trigger.style.display = "none";
                toast.style.display = "block";
                setTimeout(() => {
                    toast.style.opacity = "1";
                    toast.style.transform = "translateX(0)";
                }, 10);
                autoCloseTimeout = setTimeout(hideToast, 15000);
            };
            
            document.getElementById("close-rules-toast")?.addEventListener("click", hideToast);
            trigger.addEventListener("click", showToast);
            
            toast.style.display = "block";
            toast.style.opacity = "1";
            autoCloseTimeout = setTimeout(hideToast, 15000);
        }
        
        // Check if need password on admin pages
        if (window.location.pathname.includes('/admin/')) {
            const response = await fetch('/admin/check-auth-status', {
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            });
            const data = await response.json();
            
            if (data.banned) {
                window.location.href = '/auth/login';
                return;
            }
            
            if (!data.verified && !data.session_expired) {
                showPasswordOverlay(false);
            } else if (data.session_expired) {
                showPasswordOverlay(true);
            }
            
            startActivityTracker();
        }
        
        setTimeout(initRulesToast, 500);
        
        if (isAdmin) {
            initAdminBanOverlay();
        }
        
        setInterval(async () => {
            if (window.location.pathname.includes('/admin/')) {
                await checkBanStatus();
            }
        }, 60000);
    })();
    </script>
@endsection
EOF

chown www-data:www-data "$TARGET_FILE"
echo "✅ [ikhsan-project] Core Template dengan Admin Ban Overlay & Neon UI berhasil dipasang!"