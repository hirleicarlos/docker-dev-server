#!/bin/sh
set -e

PROJECT_ROOT="/var/www/html"

if [ -d "$PROJECT_ROOT" ]; then

    echo "Corrigindo permissões dos projetos em $PROJECT_ROOT..."

    chown -R www-data:www-data "$PROJECT_ROOT"

    find "$PROJECT_ROOT" -type d -exec chmod 755 {} \;
    find "$PROJECT_ROOT" -type f -exec chmod 644 {} \;

    # criar pastas comuns usadas por CMS
    for dir in $(find "$PROJECT_ROOT" -maxdepth 2 -type d); do
        mkdir -p "$dir/tmp" 2>/dev/null || true
        mkdir -p "$dir/cache" 2>/dev/null || true
        mkdir -p "$dir/images" 2>/dev/null || true
        mkdir -p "$dir/administrator/logs" 2>/dev/null || true
    done

fi

exec "$@"