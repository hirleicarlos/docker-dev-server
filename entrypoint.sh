#!/bin/sh
set -e

PROJECT_ROOT="/var/www/html"

if [ -d "$PROJECT_ROOT" ]; then

    echo "Corrigindo permissões dos projetos em $PROJECT_ROOT..."

    chown -R www-data:www-data "$PROJECT_ROOT"

    find "$PROJECT_ROOT" -type d -exec chmod 755 {} \;
    find "$PROJECT_ROOT" -type f -exec chmod 644 {} \;
    
fi

exec "$@"