# Hirlei Carlos - Docker Development Server

![Status](https://img.shields.io/badge/status-ativo-success)
![Stack](https://img.shields.io/badge/stack-Docker%20%7C%20Apache%20%7C%20Nginx-blue)
![PHP](https://img.shields.io/badge/PHP-8.3%20%7C%208.4-777BB4)
![Bancos](https://img.shields.io/badge/db-MariaDB%2011%20%7C%20PostgreSQL%2017-green)
![SSL](https://img.shields.io/badge/SSL-local-orange)
![Windows](https://img.shields.io/badge/Windows-Docker%20Desktop%20%2B%20WSL-black)

---

## Visão Geral

Este repositório mantém um ambiente local de desenvolvimento web com Docker Desktop no Windows e integração WSL/Ubuntu.

O servidor foi organizado para testar a mesma base de projetos em dois servidores web separados:

- Apache, acessado por domínios `*.1.localhost`
- Nginx, acessado por domínios `*.2.localhost`
- PHP 8.3, alinhado ao ambiente usado nos servidores e clientes
- MariaDB 11 para Joomla, WordPress e aplicações PHP
- PostgreSQL 17 para testes com Joomla 6 e outros projetos
- SSL local com CA própria, sem versionar certificados privados
- HAProxy como roteador frontal nas portas locais 80 e 443

O objetivo é permitir testes reais entre Apache e Nginx sem depender de portas visíveis no navegador.

---

## Arquitetura

```text
Navegador Windows
      |
      | http/https
      v
127.0.0.1:80 / 127.0.0.1:443
      |
      v
docker_router - HAProxy
      |
      +-- *.1.localhost  -> localhost1 - Apache
      |                                      |
      +-- *.2.localhost  -> localhost2 - Nginx
                                             |
                                             v
                                    php-fpm-active:9000
                                      alias de rede
                                             |
                          +------------------+------------------+
                          |                                     |
                  php_fpm_server                        php_fpm_84_server
                     PHP 8.3                                PHP 8.4
                          \___________ um por vez ___________/
```

O Nginx não passa pelo Apache. O roteamento acontece antes, no container `docker_router`.

Apache e Nginx **não executam PHP**. Os dois delegam para o mesmo PHP-FPM, através do alias de rede
`php-fpm-active`. Trocar a versão do PHP muda os dois servidores de uma vez. Ver a seção
**Versão do PHP**.

---

## Acessos Locais

### Joomla 6

| Ambiente | URL | Servidor |
|----------|-----|----------|
| Apache | `https://joomla6.1.localhost/` | `localhost1` |
| Nginx | `https://joomla6.2.localhost/` | `localhost2` |
| Padrão legado | `https://joomla6.localhost/` | Apache |

### Joomla 5

| Ambiente | URL | Servidor |
|----------|-----|----------|
| Apache | `https://joomla5.1.localhost/` | `localhost1` |
| Nginx | `https://joomla5.2.localhost/` | `localhost2` |
| Padrão legado | `https://joomla5.localhost/` | Apache |

### Site pessoal

| Ambiente | URL | Servidor |
|----------|-----|----------|
| Apache | `https://hirleicarlos-github-io.1.localhost/` | `localhost1` |
| Nginx | `https://hirleicarlos-github-io.2.localhost/` | `localhost2` + `php_fpm_server` |
| Produção | `https://hirleicarlos.github.io/` | GitHub Pages |

O repositório local do site fica em:

```text
/home/hirleicarlos/projetos/meg-load/hirleicarlos-github-io
```

Como o projeto está dentro da pasta `meg-load`, Apache e Nginx possuem um mapeamento explícito para esse diretório. O acesso Nginx continua direto ao PHP-FPM, sem passar pelo Apache.

### Ferramentas

| Serviço | URL |
|---------|-----|
| phpMyAdmin | `http://localhost:8081/` |
| Mailpit | `http://localhost:8025/` |
| Node | `http://localhost:3000/` |
| Node alternativo | `http://localhost:8082/` |

> Não use `:8443` para o Nginx nesta versão. O acesso correto é sem porta: `https://projeto.2.localhost/`.

---

## Estrutura do Projeto

```text
docker-server/
|
|-- docker-compose.yml
|-- Dockerfile
|-- Dockerfile.fpm
|-- entrypoint.sh
|-- php-switch.sh            troca o PHP entre 8.3 e 8.4
|-- .env.example
|
|-- apache/
|   |-- conf/
|   |   |-- servername.conf
|   |   `-- php-version.conf   handler FastCGI, montado como volume
|   `-- sites/
|       |-- vhost.conf
|       `-- vhost-ssl.conf
|
|-- haproxy/
|   `-- haproxy.cfg
|
|-- nginx/
|   `-- conf/
|       `-- default.conf
|
|-- php/
|   `-- php.ini
|
`-- ssl/
    |-- openssl-localhost.cnf
    |-- openssl-root-ca.cnf
    |-- local-root-ca.crt        gerado localmente, ignorado no Git
    |-- local-root-ca.key        gerado localmente, ignorado no Git
    |-- localhost.crt           gerado localmente, ignorado no Git
    `-- localhost.key           gerado localmente, ignorado no Git
```

---

## Serviços Docker

| Serviço Compose | Container | Imagem | Função |
|-----------------|-----------|--------|--------|
| `router` | `docker_router` | `haproxy:3.2-alpine` | Entrada HTTP/HTTPS e roteamento por host |
| `web` | `localhost1` | `docker-dev-server-apache:local` | Apache, sem mod_php, delega ao PHP-FPM |
| `nginx` | `localhost2` | `nginx:1.29-alpine` | Nginx separado |
| `php-fpm` | `php_fpm_server` | `docker-dev-server-php-fpm:local` | PHP-FPM 8.3, alias `php-fpm-active` |
| `php-fpm-84` | `php_fpm_84_server` | `docker-dev-server-php-fpm-84:local` | PHP-FPM 8.4, alias `php-fpm-active`, profile `php84` |
| `db` | `mariadb_server` | `mariadb:11` | Banco MariaDB |
| `mysql57` | `mysql57_server` | `mysql:5.7` | MySQL 5.7 para espelhar hospedagens |
| `postgres` | `postgres_server` | `postgres:17` | Banco PostgreSQL |
| `phpmyadmin` | `phpmyadmin_server` | `phpmyadmin:latest` | Administração MariaDB |
| `mailpit` | `mailpit_server` | `axllent/mailpit:latest` | Caixa de entrada de desenvolvimento |
| `node` | `node_server` | `node:20` | Ambiente Node.js |

---

## Versão do PHP

Apache e Nginx rodam sempre a **mesma** versão de PHP, para todos os projetos. A troca entre 8.3 e
8.4 é uma operação de segundos e não exige rebuild nem editar configuração.

### Como funciona

Nenhum dos dois servidores executa PHP. O Apache teve o `mod_php` desabilitado e usa
`mod_proxy_fcgi`; o Nginx usa `fastcgi_pass`. Os dois apontam para o mesmo destino:

```text
php-fpm-active:9000
```

`php-fpm-active` é um **alias de rede** compartilhado pelos containers `php_fpm_server` (8.3) e
`php_fpm_84_server` (8.4). Só um deles fica no ar por vez, e é ele quem responde pelo alias. Por isso
a configuração do Apache e do Nginx nunca muda.

O 8.4 fica no profile `php84` do Compose, para não subir por engano junto com o 8.3.

### Trocar de versão

```bash
cd ~/docker-server && ./php-switch.sh 8.4
```

```bash
cd ~/docker-server && ./php-switch.sh 8.3
```

Ver qual está ativa:

```bash
cd ~/docker-server && ./php-switch.sh
```

O script para o container da versão anterior antes de subir a nova, recarrega Apache e Nginx e
confirma a versão no final.

### Por que não deixar os dois no ar

Os dois containers respondem pelo mesmo alias de rede. Se ambos estiverem rodando, o DNS interno do
Docker passa a alternar entre eles, e parte das requisições cai na versão errada, de forma
intermitente e difícil de diagnosticar. O `php-switch.sh` existe justamente para impedir isso; ele
detecta e avisa se os dois estiverem no ar.

### Rodar comandos de terminal

```bash
docker compose exec php-fpm bash                      # PHP 8.3
docker compose --profile php84 exec php-fpm-84 bash   # PHP 8.4
```

Os dois têm Composer 2 e enxergam `db` e `postgres` pelos mesmos nomes de host, então dá para usar o
container da versão parada para rodar um Composer pontual sem trocar o ambiente inteiro.

### O que mudou em relação ao mod_php

| Antes | Agora |
|---|---|
| Apache executava PHP internamente (`mod_php`) | Apache delega ao PHP-FPM (`mod_proxy_fcgi`) |
| Apache e Nginx podiam divergir de versão | Sempre a mesma versão nos dois |
| Trocar versão exigia rebuild da imagem | Troca em segundos, sem rebuild |
| `php_value` e `php_flag` funcionavam no `.htaccess` | **Deixam de funcionar** |

A última linha é a única perda real. Configuração de PHP passa a ser feita em `php/php.ini`, que vale
para os dois containers FPM. Nenhum `.htaccess` dos projetos atuais usava essas diretivas.

---

## E-mail em Desenvolvimento

O Mailpit intercepta **todo** e-mail enviado pelos projetos da stack e o retém numa caixa de entrada
local. Nada sai para a internet.

Isso não é só conveniência. Ao trabalhar com dump de banco de produção, uma rotina de e-mail
disparada por engano mandaria mensagem real para endereço real de cliente. Com o Mailpit no caminho,
isso não acontece.

### Interface

```text
http://localhost:8025/
```

### Configuração nas aplicações

Dentro dos containers, o Mailpit responde pelo nome de host `mailpit`, sem autenticação:

```env
MAIL_MAILER=smtp
MAIL_HOST=mailpit
MAIL_PORT=1025
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
```

Para Joomla, em `Sistema → Configuração Global → Servidor → Correio`: método SMTP, host `mailpit`,
porta `1025`, sem autenticação e sem segurança.

Se a aplicação rodar fora do Docker, usar `127.0.0.1` no lugar de `mailpit`.

### Função mail() do PHP

As imagens PHP-FPM 8.3 e 8.4 incluem o **msmtp**, que fornece o binário `/usr/sbin/sendmail`. Sem
ele, `mail()` retornava `false` com `sendmail: not found`, falhando em silêncio.

O msmtp não entrega diretamente ao destino: ele repassa a um servidor declarado em
`php/msmtprc`, hoje apontando para o Mailpit. Ou seja, `mail()` funciona, mas a mensagem fica retida
na caixa local.

Aplicações Laravel precisam de um ajuste: o padrão do framework é `sendmail -bs`, modo que o msmtp
não implementa. Usar `-t`:

```env
MAIL_SENDMAIL_PATH="/usr/sbin/sendmail -t -i"
```

### Verificar por linha de comando

```bash
curl -s http://127.0.0.1:8025/api/v1/messages | head -40
```

Retenção de 500 mensagens; as mais antigas são descartadas automaticamente. A caixa é volátil: ao
recriar o container, o histórico se perde. É o comportamento desejado para um ambiente de teste.

---

## Parar, Limpar e Reconstruir sem Perder os Bancos

Os dados de MariaDB e PostgreSQL ficam em **bind mounts**, não em volumes gerenciados pelo Docker:

```text
/home/hirleicarlos/db          -> /var/lib/mysql
/home/hirleicarlos/postgres    -> /var/lib/postgresql/data
```

São pastas comuns do seu WSL. Nenhum comando do Docker apaga isso, nem `docker compose down -v`, nem
`docker system prune`. O único jeito de perder esses dados é apagando as pastas na mão.

### Sequência completa

Parar e remover os containers, sem tocar em imagens nem dados:

```bash
cd ~/docker-server && docker compose --profile php84 down --remove-orphans
```

Limpar o cache de build (libera espaço, não remove imagens em uso nem dados):

```bash
docker builder prune -f
```

Reconstruir as imagens do zero, incluindo a do PHP 8.4:

```bash
cd ~/docker-server && docker compose --profile php84 build --no-cache
```

Subir tudo de novo, com o PHP 8.3 ativo:

```bash
cd ~/docker-server && docker compose up -d --force-recreate
```

Conferir:

```bash
cd ~/docker-server && docker compose ps && ./php-switch.sh
```

### O que NÃO usar

| Comando | Por quê |
|---|---|
| `docker compose down -v` | A flag `-v` remove volumes nomeados. Aqui não há nenhum com dado de banco, então não causaria perda, mas é hábito perigoso de carregar para outros projetos |
| `docker system prune -a --volumes` | Remove volumes de **todos** os projetos da máquina, não só deste |
| `rm -rf ~/db` ou `~/postgres` | Este sim apaga os bancos, de forma definitiva |

### Backup antes de mexer, se quiser dormir tranquilo

```bash
docker compose exec db sh -c 'mariadb-dump -u root -p"$MARIADB_ROOT_PASSWORD" --all-databases' > ~/backup-mariadb-$(date +%F).sql
```

---

## Variáveis de Ambiente

Copie o exemplo:

```bash
cp .env.example .env
```

Configuração principal usada neste ambiente:

```env
PROJECTS_PATH=/home/hirleicarlos/projetos
DB_PATH=/home/hirleicarlos/db
POSTGRES_PATH=/home/hirleicarlos/postgres

HOST_UID=1000
HOST_GID=1000
PHP_VERSION=8.3
PHP_VERSION_84=8.4

MARIADB_DATABASE=joomla6
MARIADB_USER=joomla
MARIADB_PASSWORD=joomla

POSTGRES_DB=postgres
POSTGRES_USER=joomla
POSTGRES_PASSWORD=joomla

ROUTER_BIND_IP=127.0.0.1
ROUTER_HTTP_PORT=80
ROUTER_HTTPS_PORT=443

DB_PORT=3307
POSTGRES_PORT=5432
PHPMYADMIN_PORT=8081
NODE_PORT=3000
NODE_ALT_PORT=8082
```

Use caminhos Linux no `.env`, porque o Compose roda dentro do Ubuntu/WSL. Não use `\\wsl.localhost\...` nos volumes do Docker.

---

## SSL Local

Os arquivos de certificado não entram no Git. Apenas os arquivos `.cnf` ficam versionados para permitir recriar a estrutura.

Gerar a CA local e o certificado do servidor:

```bash
mkdir -p ssl

openssl req -x509 -nodes -newkey rsa:4096 -days 3650 \
  -keyout ssl/local-root-ca.key \
  -out ssl/local-root-ca.crt \
  -config ssl/openssl-root-ca.cnf \
  -extensions v3_ca

openssl req -new -nodes -newkey rsa:2048 \
  -keyout ssl/localhost.key \
  -out ssl/localhost.csr \
  -config ssl/openssl-localhost.cnf

openssl x509 -req \
  -in ssl/localhost.csr \
  -CA ssl/local-root-ca.crt \
  -CAkey ssl/local-root-ca.key \
  -CAcreateserial \
  -out ssl/localhost.crt \
  -days 825 \
  -sha256 \
  -extfile ssl/openssl-localhost.cnf \
  -extensions v3_req

chmod 600 ssl/*.key
chmod 644 ssl/*.crt ssl/*.csr ssl/*.srl
```

Confiar a CA no Windows, no usuário atual:

```powershell
Import-Certificate `
  -FilePath "\\wsl.localhost\Ubuntu\home\hirleicarlos\docker-server\ssl\local-root-ca.crt" `
  -CertStoreLocation Cert:\CurrentUser\Root
```

No Firefox, habilite `security.enterprise_roots.enabled=true` em `about:config` e reinicie o navegador.

---

## Docker Desktop no Windows

Este projeto deve ser executado pelo WSL, usando o engine do Docker Desktop.

No Docker Desktop, confira:

```text
Settings > Resources > WSL Integration > Ubuntu habilitado
```

Subir pelo PowerShell:

```powershell
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose config
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose up -d --build
```

Subir dentro do Ubuntu/WSL:

```bash
cd /home/hirleicarlos/docker-server
docker compose config
docker compose up -d --build
```

Verificar se Windows e WSL estão usando o mesmo Docker:

```powershell
docker info --format "{{.OperatingSystem}}"
wsl -d Ubuntu -- docker info --format "{{.OperatingSystem}}"
```

---

## Fluxo Padrão Após Mudanças

Sempre que alterar `docker-compose.yml`, `Dockerfile`, `Dockerfile.fpm`, Apache, Nginx, HAProxy, PHP ou SSL, recrie a stack.

PowerShell:

```powershell
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose down --remove-orphans
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose build --no-cache
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose up -d --force-recreate
```

Ubuntu/WSL:

```bash
cd /home/hirleicarlos/docker-server
docker compose --profile php84 down --remove-orphans
docker compose --profile php84 build --no-cache
docker compose up -d --force-recreate
```

O `--profile php84` é necessário nos dois primeiros comandos para que o container do PHP 8.4 também
seja parado e reconstruído. No `up` ele fica de fora de propósito, porque só uma versão roda por vez.

Esse fluxo recria containers e imagens, mas preserva os dados em:

```text
/home/hirleicarlos/db
/home/hirleicarlos/postgres
```

---

## Hosts do Windows

Para os principais domínios locais, use:

```text
127.0.0.1 joomla5.localhost joomla6.localhost joomla5.1.localhost joomla6.1.localhost joomla5.2.localhost joomla6.2.localhost hirleicarlos-github-io.1.localhost hirleicarlos-github-io.2.localhost _phpcheck.1.localhost _phpcheck.2.localhost db-sync-ide.2.localhost localhost1 localhost2
```

Local do arquivo:

```text
C:\Windows\System32\drivers\etc\hosts
```

Domínios terminados em `.localhost` geralmente resolvem para `127.0.0.1`, mas o `hosts` deixa o ambiente previsível no Windows e no Firefox.

---

## Bancos de Dados

### MariaDB

Uso interno nos containers:

```text
Host: db
Porta: 3306
Banco: joomla6
Usuario: joomla
Senha: joomla
```

Uso no Windows/DBeaver:

```text
Host: localhost
Porta: 3307
Banco: joomla6
Usuario: joomla
Senha: joomla
```

### MySQL 5.7

Existe para espelhar o motor das hospedagens dos clientes, que costumam estar em
MySQL 5.7, e não em MariaDB. Sem ele, o primeiro teste de um SQL gerado seria contra o banco de
produção do cliente.

Uso interno nos containers:

```text
Host: mysql57
Porta: 3306
Usuario: joomla
Senha: joomla
```

Uso no Windows/DBeaver:

```text
Host: localhost
Porta: 3308
Usuario: joomla
Senha: joomla
```

Dados em `/home/hirleicarlos/db-mysql57`, separados do MariaDB.

**Por que isso importa.** MariaDB e MySQL divergem em collation e em tipos. Uma coluna criada no
MariaDB 11 com `utf8mb3_uca1400_ai_ci` não pode ser recriada em MySQL:

```text
ERROR 1273 (HY000): Unknown collation: 'utf8mb3_uca1400_ai_ci'
```

O servidor sobe com `utf8mb4` e `sql_mode` estrito, para que o charset de cada banco seja escolha
explícita na criação e erros de dado apareçam no teste, não em produção.

### PostgreSQL

Uso interno nos containers:

```text
Host: postgres
Porta: 5432
Banco inicial: postgres
Usuario: joomla
Senha: joomla
```

Uso no Windows/DBeaver:

```text
Host: localhost
Porta: 5432
Banco inicial: postgres
Usuario: joomla
Senha: joomla
```

O PostgreSQL inicia em `postgres` para permitir criar e apagar bancos Joomla manualmente pelo DBeaver. Para apagar um banco, conecte em `postgres`, não no banco que será excluído.

---

## Comandos Úteis

Status dos containers:

```bash
docker compose ps
```

Logs gerais:

```bash
docker compose logs -f
```

Logs de um serviço:

```bash
docker compose logs -f router
docker compose logs -f web
docker compose logs -f nginx
docker compose logs -f php-fpm
docker compose logs -f php-fpm-84
docker compose logs -f postgres
```

Acessar containers:

```bash
docker compose exec web bash
docker compose exec php-fpm bash
docker compose exec postgres psql -U joomla -d postgres
docker compose exec db mariadb -u joomla -pjoomla joomla6
```

Parar:

```bash
docker compose down
```

Reiniciar:

```bash
docker compose restart
```

---

## Testes Rápidos

Validar Apache:

```bash
curl -k -I https://joomla6.1.localhost/
```

Validar Nginx:

```bash
curl -k -I https://joomla6.2.localhost/
```

Validar roteamento HTTP:

```bash
curl -I http://joomla6.1.localhost/
curl -I http://joomla6.2.localhost/
```

Validar o site pessoal nos dois servidores:

```bash
curl -k -I https://hirleicarlos-github-io.1.localhost/
curl -k -I https://hirleicarlos-github-io.2.localhost/
```

Validar a versão de PHP nos dois servidores de uma vez, com o verificador em
`~/projetos/_phpcheck/`:

```bash
curl -s -H 'Host: _phpcheck.1.localhost' http://127.0.0.1/ && curl -s -H 'Host: _phpcheck.2.localhost' http://127.0.0.1/
```

Ele responde versão do PHP, SAPI, qual servidor atendeu, o ID do container PHP-FPM e a conexão com
MariaDB e PostgreSQL. O campo `Container` deve ser **idêntico** nas duas respostas: é a prova de que
Apache e Nginx estão no mesmo PHP-FPM. Se divergirem, os dois containers estão no ar ao mesmo tempo e
o `./php-switch.sh` precisa ser rodado.

No navegador: `https://_phpcheck.1.localhost/` e `https://_phpcheck.2.localhost/`.

Validar bancos:

```bash
docker compose exec db mariadb -u joomla -pjoomla -e "SELECT VERSION();"
docker compose exec postgres psql -U joomla -d postgres -c "SELECT version();"
```

---

## Arquivos Locais Não Versionados

Este projeto ignora arquivos locais e sensíveis:

| Caminho | Motivo |
|---------|--------|
| `.env` | Senhas, portas e caminhos locais |
| `ssl/*.key` | Chaves privadas SSL |
| `ssl/*.crt` | Certificados gerados localmente |
| `ssl/*.csr` | Requisições de certificado |
| `ssl/*.srl` | Serial da CA local |
| `.claude/` | Configuração local de agente |
| `AGENTS.md` | Instruções locais de agente |
| `CLAUDE.md` | Instruções locais de agente |

---

## Princípios de Engenharia

| Princípio | Aplicação |
|-----------|-----------|
| Separação real de servidores | Apache e Nginx rodam em containers diferentes |
| Entrada única | HAProxy recebe 80/443 e roteia por domínio |
| SSL local reproduzível | `.cnf` versionado, certificados privados ignorados |
| PHP único e trocável | Apache e Nginx delegam ao mesmo PHP-FPM; a troca 8.3 ↔ 8.4 vale para os dois de uma vez |
| Bancos independentes | MariaDB e PostgreSQL rodam separados |
| Compatível com Docker Desktop | Compose executado no WSL com engine do Windows |
| Rebuild previsível | Fluxo padrão com `down`, `build --no-cache` e `up --force-recreate` |

---

## 📬 Contato

- 🌐 Site: [hirleicarlos.github.io](https://hirleicarlos.github.io)
- 💼 LinkedIn: [linkedin.com/in/hirleicarlos](https://linkedin.com/in/hirleicarlos)
- 🐙 GitHub: [github.com/hirleicarlos](https://github.com/hirleicarlos)
- ✉️ E-mail: prof.hirleicarlos@gmail.com

---

© 2026 — Hirlei Carlos<br>
Desenvolvedor Full Stack Sênior | PHP & Joomla | Sistemas Corporativos | Docker | Governo e Educação
