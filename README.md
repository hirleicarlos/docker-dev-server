# Docker Development Server

Ambiente de desenvolvimento web utilizando **Docker**, configurado com **Apache, PHP e HTTPS local** para facilitar o desenvolvimento de aplicações web em ambiente isolado.

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
* PHP
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
docker exec -it docker-dev-server bash
```

---

# Acessar o servidor no navegador

Após iniciar o ambiente, o servidor poderá ser acessado em:

```
http://pasta.localhost
https://pasta.localhost
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