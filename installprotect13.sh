#!/bin/bash
# 🛡️ ikhsan-project - Complete Installation Script
# Run: sudo bash install_all.sh

echo "=========================================="
echo "  🛡️ ikhsan-project Security Suite v2.0"
echo "  Complete Ban System with Admin Panel"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}🚀 Installing Security System...${NC}"

# 1. Create migration
echo -e "${CYAN}📦 Creating database migration...${NC}"
bash create_migration.sh

# 2. Create Model
echo -e "${CYAN}📦 Creating BannedUser model...${NC}"
bash create_model.sh

# 3. Install all protection files
echo -e "${CYAN}📦 Installing protection files 1-10...${NC}"
bash installprotect1.sh
bash installprotect2.sh
bash installprotect3.sh
bash installprotect4.sh
bash installprotect5.sh
bash installprotect6.sh
bash installprotect7.sh
bash installprotect8.sh
bash installprotect9.sh
bash installprotect10.sh

# 4. Run Migration
echo -e "${CYAN}🗄️ Running database migration...${NC}"
php /var/www/pterodactyl/artisan migrate

# 5. Clear all caches
echo -e "${CYAN}🧹 Clearing caches...${NC}"
php /var/www/pterodactyl/artisan view:clear
php /var/www/pterodactyl/artisan cache:clear
php /var/www/pterodactyl/artisan config:clear
php /var/www/pterodactyl/artisan route:clear
php /var/www/pterodactyl/artisan optimize:clear

# 6. Set permissions
echo -e "${CYAN}🔧 Setting permissions...${NC}"
chown -R www-data:www-data /var/www/pterodactyl/storage
chown -R www-data:www-data /var/www/pterodactyl/bootstrap/cache
chmod -R 755 /var/www/pterodactyl/storage
chmod -R 755 /var/www/pterodactyl/bootstrap/cache

echo ""
echo "=========================================="
echo -e "${GREEN}  ✅ INSTALLATION COMPLETE!${NC}"
echo "=========================================="
echo -e "${CYAN}📌 SYSTEM FEATURES:${NC}"
echo "   🔒 Ban System (Database-based)"
echo "   🔐 Password Protection: 171012khanza"
echo "   ⏰ Auto-ban after 3 failed attempts (7 days)"
echo "   🕐 Auto-lockout after 5 minutes inactive"
echo "   👑 Admin ID 1: Full access + Ban Management Panel"
echo "   📊 Admin Ban Overlay: View all banned users"
echo "   🔓 Unban feature for Admin ID 1"
echo "   📞 Contact: @Ikhsanprotject"
echo "=========================================="
echo -e "${CYAN}📞 FOR SUPPORT:${NC}"
echo "   Telegram: @Ikhsanprotject"
echo "=========================================="