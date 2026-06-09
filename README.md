# Docker Development Server

Ambiente de desenvolvimento web utilizando **Docker**, configurado com **Apache, Nginx, PHP e HTTPS local** para facilitar o desenvolvimento de aplicações web em ambiente isolado.

Este ambiente permite executar diferentes tipos de projetos web em um servidor replicável e padronizado.

Pode ser utilizado para desenvolver:

* CMS (Joomla, WordPress, Drupal)
* Frameworks (Laravel, Symfony, CodeIgniter)
* Sites estáticos
* APIs
* Aplicações web personalizadas

---

# Tecnologias utilizadas

* Docker
* Docker Compose
* Apache
* Nginx
* PHP
* PHP-FPM
* MariaDB
* PostgreSQL
* SSL (HTTPS local)
* Linux / WSL

---

# Estrutura do projeto

```
docker-dev-server/
├── docker-compose.yml
├── Dockerfile
├── entrypoint.sh
├── apache/
│   ├── conf/
│   │   └── servername.conf
│   └── sites/
│       ├── vhost.conf
│       └── vhost-ssl.conf
├── php/
│   └── php.ini
└── ssl/
```

Os certificados SSL são gerados localmente após a instalação.

---

# Funcionalidades

* Ambiente de desenvolvimento containerizado
* Apache configurado com VirtualHost
* Nginx configurado para testar os mesmos projetos em paralelo
* MariaDB e PostgreSQL para testes com Joomla 6
* Suporte a HTTPS local
* Configuração customizada de PHP
* Estrutura preparada para múltiplos projetos web
* Isolamento de dependências
* Inicialização rápida utilizando Docker

---

# Requisitos

Para executar este ambiente é necessário ter instalado:

* Docker
* Docker Compose

Verifique a instalação:

```bash
docker --version
docker compose version
```

---

# Instalação

Clone o repositório:

```bash
git clone https://github.com/hirleicarlos/docker-dev-server.git
```

Entre na pasta do projeto:

```bash
cd docker-dev-server
```

---

# Gerar certificado SSL local

Como as chaves SSL não são armazenadas no repositório, é necessário gerar um certificado local.

Execute:

```bash
mkdir ssl
```

Gerar certificado:

```bash
openssl req -x509 -nodes -days 365 \
-newkey rsa:2048 \
-keyout ssl/localhost.key \
-out ssl/localhost.crt \
-subj "/C=BR/ST=Local/L=Local/O=Dev/CN=localhost"
```

Para a configuracao atual com Apache em `*.1.localhost`, Nginx em `*.2.localhost` e compatibilidade com `*.localhost1`/`*.localhost2`, prefira gerar uma CA local e um certificado de servidor assinado por ela:

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

O Apache e o Nginx usam `ssl/localhost.crt` e `ssl/localhost.key`. Para o navegador confiar sem aviso, importe `ssl/local-root-ca.crt` como autoridade raiz confiavel no Windows.

No PowerShell, para confiar a CA local no usuario atual do Windows:

```powershell
Import-Certificate -FilePath "\\wsl.localhost\Ubuntu\home\hirleicarlos\docker-server\ssl\local-root-ca.crt" -CertStoreLocation Cert:\CurrentUser\Root
```

No Firefox, habilite o uso das raizes do sistema com `security.enterprise_roots.enabled=true` e reinicie o navegador.

---

# Docker Desktop no Windows

O projeto usa Docker Desktop para Windows com integracao WSL. Como os arquivos estao dentro do Ubuntu, execute o Compose pelo WSL.

No Docker Desktop, confirme em Settings > Resources > WSL Integration que a distro Ubuntu esta habilitada.

Pelo PowerShell:

```powershell
Copy-Item .env.example .env
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose config
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose up -d --build
```

Dentro do Ubuntu/WSL:

```bash
cp .env.example .env
docker compose config
docker compose up -d --build
```

No arquivo `.env`, use caminhos Linux:

```env
PROJECTS_PATH=/home/hirleicarlos/projetos
DB_PATH=/home/hirleicarlos/db
POSTGRES_PATH=/home/hirleicarlos/postgres
```

Evite colocar `//wsl.localhost/...` nos volumes do Compose; esse caminho e para o Windows acessar arquivos do WSL e pode montar vazio no container.

Verifique se o WSL esta usando o mesmo engine do Docker Desktop:

```powershell
docker info --format "{{.OperatingSystem}}"
wsl -d Ubuntu -- docker info --format "{{.OperatingSystem}}"
```

Se o comando do Windows mostrar `Docker Desktop` e o comando do WSL mostrar `Docker Engine - Community`, existem dois engines separados. Nesse caso, ative a integracao em Docker Desktop > Settings > Resources > WSL Integration > Ubuntu, reinicie o terminal e confirme de novo antes de subir o projeto.

A imagem local do Apache sera criada como:

```text
docker-dev-server-apache:local
```

Container do Apache:

```text
localhost1
```

A imagem local do PHP-FPM usado pelo Nginx sera criada como:

```text
docker-dev-server-php-fpm:local
```

Container do Nginx:

```text
localhost2
```

Acessos principais:

```text
Apache Joomla 5: https://joomla5.1.localhost/
Nginx Joomla 5:  https://joomla5.2.localhost:8443/
Apache Joomla 6: https://joomla6.1.localhost/
Nginx Joomla 6:  https://joomla6.2.localhost:8443/
Legado:          https://joomla5.localhost/ redireciona para https://joomla5.1.localhost/
phpMyAdmin:      http://localhost:8081/
```

Nginx usa portas proprias para nao passar pelo Apache: `8080` no HTTP e `8443` no HTTPS. Os nomes `https://joomla5.localhost1/` e `https://joomla5.localhost2:8443/` continuam aceitos como compatibilidade, mas precisam de entradas no `hosts` do Windows porque `localhost1` e `localhost2` nao sao dominios reservados pelo navegador.

Banco MariaDB para Joomla:

```text
Host: db
Porta interna: 3306
Banco: joomla6
Usuario: joomla
Senha: joomla
Porta no host: 3307
```

Banco PostgreSQL para Joomla:

```text
Host: postgres
Porta interna: 5432
Banco: joomla6
Usuario: joomla
Senha: joomla
Porta no host: 5432
```

---

# Fluxo padrao apos mudancas

Sempre que alterar `docker-compose.yml`, `Dockerfile`, `Dockerfile.fpm`, configuracoes do Apache, Nginx ou PHP, limpe os containers antigos e suba tudo novamente com build.

No PowerShell, para este projeto dentro do Ubuntu/WSL:

```powershell
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose down --remove-orphans
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose build --no-cache
wsl -d Ubuntu --cd /home/hirleicarlos/docker-server -- docker compose up -d --force-recreate
```

Dentro do Ubuntu/WSL:

```bash
docker compose down --remove-orphans
docker compose build --no-cache
docker compose up -d --force-recreate
```

Isso recria os containers e atualiza as imagens locais sem apagar os dados dos bancos. Para apagar tambem os dados dos bancos, use volumes separados com cuidado.

---

# Iniciar o servidor

Execute:

```bash
docker compose up -d --build
```

---

# Parar o servidor

```bash
docker compose down
```

---

# Reiniciar o servidor

```bash
docker compose restart
```

---

# Ver logs

```bash
docker compose logs -f
```

---

# Acessar o container

```bash
docker compose exec web bash
docker compose exec php-fpm bash
docker compose exec postgres psql -U joomla -d joomla6
```

---

# Acessar o servidor no navegador

Após iniciar o ambiente, o servidor poderá ser acessado em:

```
http://pasta.localhost1
https://pasta.localhost1
```

Para testar o mesmo projeto no Nginx, use o sufixo `.localhost2`:

```
http://pasta.localhost2
https://pasta.localhost2
```

Exemplos com Joomla:

```
https://joomla5.localhost1
https://joomla5.localhost2
https://joomla6.localhost1
https://joomla6.localhost2
```

No Docker, os containers aparecem como `localhost1` para Apache e `localhost2` para Nginx. O Apache tambem faz a entrada HTTPS para os dominios `*.localhost2` e encaminha internamente para o Nginx, permitindo usar HTTPS sem porta no navegador.

Para abrir no navegador do Windows, adicione no arquivo `hosts`:

```text
127.0.0.1 localhost1
127.0.0.1 localhost2
127.0.0.1 joomla5.localhost1
127.0.0.1 joomla5.localhost2
127.0.0.1 joomla6.localhost1
127.0.0.1 joomla6.localhost2
```

Ha um arquivo pronto com as entradas principais em:

```text
/home/hirleicarlos/projetos/tarefas/Docker servidor ajustes/hosts-docker-servidor.txt
```

Adicione os domínios desejados no arquivo **hosts** do sistema.

Exemplo:

```
127.0.0.1 joomla.localhost
127.0.0.1 projeto.localhost
```

---

# Objetivo do projeto

Este projeto foi criado para fornecer um ambiente de desenvolvimento local baseado em containers e também para demonstrar conhecimentos em:

* Docker
* Containers
* Infraestrutura de desenvolvimento
* Configuração de servidores web
* DevOps básico

---

# Autor

Hirlei Carlos

🌐 Site
https://hirleicarlos.github.io

💻 GitHub
https://github.com/hirleicarlos

---

# Licença

Este projeto está disponível para estudo e uso pessoal.
