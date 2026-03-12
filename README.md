# Docker Development Server

Ambiente de desenvolvimento web utilizando **Docker**, configurado com **Apache, PHP e SSL** para facilitar o desenvolvimento de aplicações web em ambiente local.

Este ambiente permite executar diferentes tipos de projetos web em um servidor isolado e replicável.

Pode ser utilizado para desenvolver:

- CMS (Joomla, WordPress, Drupal)
- Frameworks (Laravel, Symfony, CodeIgniter)
- Sites estáticos
- APIs
- Aplicações web personalizadas

---

## Tecnologias utilizadas

- Docker
- Docker Compose
- Apache
- PHP
- SSL (HTTPS local)
- Linux / WSL

---

## Estrutura do projeto

```text
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
    ├── localhost.crt
    └── localhost.key
```

---

## Funcionalidades

- Ambiente de desenvolvimento containerizado
- Configuração Apache com VirtualHost
- Suporte a HTTPS local
- Configuração customizada de PHP
- Estrutura preparada para múltiplos projetos web
- Isolamento de dependências
- Inicialização rápida utilizando Docker

---

## Requisitos

Para executar este ambiente é necessário ter instalado:

- Docker
- Docker Compose

Verificar instalação:

```bash
docker --version
docker compose version
```

---

## Como iniciar o servidor

Clone o repositório:

```bash
git clone https://github.com/hirleicarlos/docker-dev-server.git
```

Entre na pasta do projeto:

```bash
cd docker-dev-server
```

Inicie os containers:

```bash
docker compose up -d
```

---

## Parar o servidor

```bash
docker compose down
```

---

## Reiniciar o servidor

```bash
docker compose restart
```

---

## Ver logs

```bash
docker compose logs -f
```

---

## Acessar container

```bash
docker exec -it docker-dev-server bash
```

---

## Acesso ao servidor

Após iniciar o ambiente, o servidor poderá ser acessado no navegador:

http://pasta.localhost

https://pasta.localhost

---

## Objetivo do projeto

Este projeto foi criado para fornecer um ambiente de desenvolvimento local baseado em containers e também para demonstrar conhecimentos em:

- Docker
- Containers
- Infraestrutura de desenvolvimento
- Configuração de servidores web
- DevOps básico

---

## Autor

Hirlei Carlos

🌐 Site  
https://hirleicarlos.github.io

💻 GitHub  
https://github.com/hirleicarlos

---

## Licença

Este projeto está disponível para estudo e uso pessoal.