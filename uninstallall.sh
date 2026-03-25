#!/bin/bash
echo "🔄 Memulai proses Uninstall Protect 1-11 (ikhsan-project)..."

# Daftar file yang diproteksi
declare -A FILES
FILES["/var/www/pterodactyl/app/Services/Servers/ServerDeletionService.php"]="1"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"]="2"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/LocationController.php"]="3"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/Nodes/NodeController.php"]="4"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/NestController.php"]="5"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/Settings/IndexController.php"]="6"
FILES["/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/FileController.php"]="7"
FILES["/var/www/pterodactyl/app/Http/Controllers/Api/Client/Servers/ServerController.php"]="8"
FILES["/var/www/pterodactyl/app/Services/Servers/DetailsModificationService.php"]="9"
FILES["/var/www/pterodactyl/resources/views/templates/base/core.blade.php"]="10"
FILES["/var/www/pterodactyl/app/Http/Controllers/Admin/NodesController.php"]="11"

for FILE in "${!FILES[@]}"; do
    BACKUP=$(ls ${FILE}.bak* 2>/dev/null | head -n 1)
    if [ -f "$BACKUP" ]; then
        echo "✅ Mengembalikan File Protect ${FILES[$FILE]} dari backup..."
        mv "$BACKUP" "$FILE"
    else
        echo "⚠️ Backup untuk script ${FILES[$FILE]} tidak ditemukan, melewati..."
    fi
done

# Clear cache agar perubahan langsung terasa
cd /var/www/pterodactyl && php artisan view:clear && php artisan cache:clear

echo "🎉 Uninstall Selesai! Panel kembali ke kondisi normal."