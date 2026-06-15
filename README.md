# Hirlei Carlos - Docker Development Server

![Status](https://img.shields.io/badge/status-ativo-success)
![Stack](https://img.shields.io/badge/stack-Docker%20%7C%20Apache%20%7C%20Nginx-blue)
![PHP](https://img.shields.io/badge/PHP-8.3-777BB4)
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
      +-- *.1.localhost  -> localhost1 - Apache + PHP 8.3
      |
      +-- *.2.localhost  -> localhost2 - Nginx
                              |
                              v
                         php_fpm_server - PHP-FPM 8.3
```

O Nginx não passa pelo Apache. O roteamento acontece antes, no container `docker_router`.

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
|-- .env.example
|
|-- apache/
|   |-- conf/
|   |   `-- servername.conf
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
| `web` | `localhost1` | `docker-dev-server-apache:local` | Apache + PHP 8.3 |
| `nginx` | `localhost2` | `nginx:1.29-alpine` | Nginx separado |
| `php-fpm` | `php_fpm_server` | `docker-dev-server-php-fpm:local` | PHP-FPM 8.3 para Nginx |
| `db` | `mariadb_server` | `mariadb:11` | Banco MariaDB |
| `postgres` | `postgres_server` | `postgres:17` | Banco PostgreSQL |
| `phpmyadmin` | `phpmyadmin_server` | `phpmyadmin:latest` | Administração MariaDB |
| `node` | `node_server` | `node:20` | Ambiente Node.js |

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
docker compose down --remove-orphans
docker compose build --no-cache
docker compose up -d --force-recreate
```

Esse fluxo recria containers e imagens, mas preserva os dados em:

```text
/home/hirleicarlos/db
/home/hirleicarlos/postgres
```

---

## Hosts do Windows

Para os principais domínios locais, use:

```text
127.0.0.1 joomla5.localhost joomla6.localhost joomla5.1.localhost joomla6.1.localhost joomla5.2.localhost joomla6.2.localhost hirleicarlos-github-io.1.localhost hirleicarlos-github-io.2.localhost localhost1 localhost2
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
| PHP consistente | Apache e PHP-FPM usam PHP 8.3 |
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
