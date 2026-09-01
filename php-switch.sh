#!/usr/bin/env bash
#
# Deixa uma unica versao de PHP no ar, para Apache e Nginx ao mesmo tempo.
#
# Os dois servidores apontam para o alias de rede "php-fpm-active", compartilhado
# pelos containers php_fpm_server (8.3), php_fpm_84_server (8.4) e
# php_fpm_85_server (8.5). Apenas um pode ocupar o alias por vez, senao o DNS do
# Docker alterna entre eles e parte das requisicoes vai para a versao errada.
#
# Os servicos NAO usam "profiles" do Compose: com profile eles sumiam da
# listagem do Compose e do Dockge quando parados, e a ideia e poder ligar e
# desligar cada versao pela interface. O preco e que "docker compose up -d"
# sobe as tres de uma vez. Depois de um "up -d", rode este script para deixar
# so uma no ar.
#
# Uso:
#   ./php-switch.sh 8.3
#   ./php-switch.sh 8.4
#   ./php-switch.sh 8.5
#   ./php-switch.sh          mostra a versao ativa
#
set -euo pipefail

cd "$(dirname "$0")"

# Versoes conhecidas, no formato:
#   <versao>|<servico fpm>|<servico worker>|<container fpm>|<container worker>
#
# O container do worker vai explicito porque o do 8.3 se chama "worker_server",
# fora do padrao "worker_NN_server" das outras versoes.
#
# Para acrescentar uma versao nova basta incluir a linha aqui e os dois
# servicos correspondentes no docker-compose.yml.
VERSOES=(
    "8.3|php-fpm|worker|php_fpm_server|worker_server"
    "8.4|php-fpm-84|worker-84|php_fpm_84_server|worker_84_server"
    "8.5|php-fpm-85|worker-85|php_fpm_85_server|worker_85_server"
)

campo() {
    # campo <linha> <indice>
    echo "$1" | cut -d"|" -f"$2"
}

linha_da_versao() {
    local alvo="$1" linha
    for linha in "${VERSOES[@]}"; do
        if [ "$(campo "$linha" 1)" = "$alvo" ]; then
            echo "$linha"
            return 0
        fi
    done
    return 1
}

esta_no_ar() {
    [ -n "$(docker ps -q -f "name=^${1}$" -f "status=running" 2>/dev/null)" ]
}

versao_ativa() {
    local ativas="" linha
    for linha in "${VERSOES[@]}"; do
        if esta_no_ar "$(campo "$linha" 4)"; then
            ativas="${ativas}$(campo "$linha" 1) "
        fi
    done
    ativas="${ativas% }"

    case "$(echo "$ativas" | wc -w)" in
        0) echo "nenhuma" ;;
        1) echo "$ativas" ;;
        *) echo "conflito:${ativas}" ;;
    esac
}

mostrar_status() {
    local atual
    atual="$(versao_ativa)"

    case "$atual" in
        conflito:*)
            echo "ATENCAO: mais de um PHP-FPM no ar ao mesmo tempo (${atual#conflito:})."
            echo "Eles dividem o alias php-fpm-active e o roteamento fica imprevisivel."
            echo "Rode: ./php-switch.sh 8.3   (ou 8.4, ou 8.5)"
            ;;
        nenhuma)
            echo "Nenhum PHP-FPM no ar. O PHP nao vai executar em nenhum servidor."
            echo "Rode: ./php-switch.sh 8.3   (ou 8.4, ou 8.5)"
            ;;
        *)
            echo "PHP ativo: ${atual}  (Apache e Nginx)"
            ;;
    esac
}

if [ $# -eq 0 ]; then
    mostrar_status
    echo
    echo "Versoes instaladas:"
    for linha in "${VERSOES[@]}"; do
        v="$(campo "$linha" 1)"
        if esta_no_ar "$(campo "$linha" 4)"; then
            printf '  %s  no ar\n' "$v"
        else
            printf '  %s  parada\n' "$v"
        fi
    done
    exit 0
fi

alvo="$1"

# Aceita 83, 84 e 85 alem de 8.3, 8.4 e 8.5.
case "$alvo" in
    83) alvo="8.3" ;;
    84) alvo="8.4" ;;
    85) alvo="8.5" ;;
esac

if ! linha_alvo="$(linha_da_versao "$alvo")"; then
    echo "Versao invalida: ${alvo}. Use 8.3, 8.4 ou 8.5." >&2
    exit 1
fi

fpm_alvo="$(campo "$linha_alvo" 2)"
wrk_alvo="$(campo "$linha_alvo" 3)"
ct_alvo="$(campo "$linha_alvo" 4)"

echo "Trocando para PHP ${alvo}..."

# Para as outras PRIMEIRO. Se duas ficarem no ar com o mesmo alias de rede, o
# Docker passa a alternar entre elas e parte das requisicoes vai para a versao
# errada.
#
# Para sempre, sem checar antes se esta no ar: o worker e um container separado
# do PHP-FPM. Parando o FPM na mao e rodando o switch depois, o worker antigo
# continuava vivo junto com a versao nova. Estado misto, dificil de perceber.
for linha in "${VERSOES[@]}"; do
    if [ "$(campo "$linha" 1)" = "$alvo" ]; then
        continue
    fi

    echo "  parando PHP $(campo "$linha" 1)"
    docker compose stop "$(campo "$linha" 2)" "$(campo "$linha" 3)" >/dev/null 2>&1 || true
done

echo "  subindo ${fpm_alvo} e ${wrk_alvo}"
docker compose up -d "$fpm_alvo" "$wrk_alvo" >/dev/null

# O Apache guarda a resolucao de DNS do backend FastCGI. Sem o reload ele
# continua mandando para o container antigo ate expirar o cache.
echo "  recarregando Apache e Nginx"
docker compose restart web nginx >/dev/null

echo
mostrar_status
echo
docker exec "$ct_alvo" php -v | head -1

# Confere que nenhum container de outra versao sobrou. Vale para o FPM e para o
# worker: um worker de versao errada roda a fila num PHP diferente do que serve
# as paginas.
sobrou=""
for linha in "${VERSOES[@]}"; do
    if [ "$(campo "$linha" 1)" = "$alvo" ]; then
        continue
    fi
    for ct in "$(campo "$linha" 4)" "$(campo "$linha" 5)"; do
        if esta_no_ar "$ct"; then
            sobrou="${sobrou} ${ct}"
        fi
    done
done

if [ -n "$sobrou" ]; then
    echo
    echo "ATENCAO: sobrou container de outra versao no ar:${sobrou}"
    echo "Rode de novo, ou pare na mao com: docker compose stop <servico>"
fi
