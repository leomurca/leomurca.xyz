---
title: "Como fazer o deploy de aplicativos React usando Github Actions + Rsync"
date: 2022-10-15T15:30:22-03:00
lastmod: 2024-03-24
description: "Aprenda como fazer o deploy de aplicativos React usando Github Actions + Rsync"
featured_image: "/img/how-to-deploy-react-applications-using-github-actions-+-rsync/featured_image.webp"
draft: false
---

![Gato com olhos amarelos](/img/how-to-deploy-react-applications-using-github-actions-+-rsync/cover-image-1.webp)

Código fonte e aplicação em produção utilizado nesse post:
- [rsync-deploy-react-app](https://github.com/leomurca/rsync-deploy-react-app);
- [tutorials.leomurca.xyz/rsync-deploy-react-app](https://tutorials.leomurca.xyz/rsync-deploy-react-app/);

## TL;DR

- Crie um usuário em seu servidor para fazer o deploy de sua aplicação:
```shell
$ useradd -s /bin/bash -d /home/tutorials -m tutorials
$ su tutorials
```

- Crie um diretório para copiar seus arquivos de produção:
```shell
$ mkdir rsync-deploy-react-app
```

- Add your private tutorials's user ssh key to your [Action Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

- Adicione a chave ssh privada do usuário `tutorials` aos seus [Action Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets).

- Crie uma nova action no github para fazer o deploy da sua aplicação e cole o código abaixo:
```yml
# .github/workflows/deploy.yml
name: Deploy 

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-deploy:

    runs-on: ubuntu-latest

    env:
      SSH_KEY: ${{secrets.SSH_KEY}}

    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js 16
      uses: actions/setup-node@v3
      with:
        node-version: 16
        cache: 'npm'
    - run: mkdir ~/.ssh
    - run: 'echo "$SSH_KEY" >> ~/.ssh/id_rsa_tutorials'
    - run: chmod 400 ~/.ssh/id_rsa_tutorials
    - run: echo -e "Host tutorials\n\tUser tutorials\n\tHostname 45.76.5.44\n\tIdentityFile ~/.ssh/id_rsa_tutorials\n\tStrictHostKeyChecking No" >> ~/.ssh/config
    - run: npm install
    - run: npm run build
    - run: rsync -avz --progress build/ tutorials:/home/tutorials/rsync-deploy-react-app --delete
```

Preste atenção aos **Pré-requisitos**. É isso! Altere algum código, envie-o para o branch principal e veja a mágica acontecendo!

## Motivação 

Estive trabalhando em minha tese de bacharelado em sistemas de informação, que é um aplicativo React simples, e estava lutando para encontrar uma maneira **simples, segura e rápida** de implantá-lo em meu próprio [VPS](https:/ /en.wikipedia.org/wiki/Virtual_private_server). No entanto, a maior parte do conteúdo que encontrei na internet envolve soluções **fantasiosas e complexas** como [docker](https://www.docker.com/) e [Kubernetes](https://kubernetes.io /) ou soluções **bloqueadas pelo fornecedor** como [Heroku](https://www.heroku.com/) e [Vercel](https://vercel.com/).

Reconheço que essas ferramentas têm suas vantagens, mas descobri que, para projetos de pequeno e médio porte, elas exigem mais esforço do que vale a pena manter. Tudo o que preciso fazer é criar o código e copiar os arquivos criados para o servidor. Então, [rsync](https://en.wikipedia.org/wiki/Rsync) chegou ao meu conhecimento.

## Pré-requisitos

- Uma aplicação React existente;
- Um servidor ou um serviço de hospedagem para fazer o deploy de sua aplicação;
- Seu próprio domínio registrado;
- [NGINX](https://www.nginx.com/) instalado em seu servidor;
- Algum conhecimento sobre como registrar um domínio e criar um servidor em alguma plataforma de hospedagem (adicionarei artigos sobre isso no futuro).

## Aplicativo de demonstração a ser implantado

Criei um aplicativo de demonstração para fazer o deploy em meu servidor. Seu código-fonte está disponível em [rsync-deploy-react-app](https://github.com/leomurca/rsync-deploy-react-app).

![Screenshot da aplicação escrita em React](/img/how-to-deploy-react-applications-using-github-actions-+-rsync/app-screenshot-2.webp)

## Setup do servidor

Para este tutorial, usarei meu domínio `leomurca.xyz` configurando um subdomínio para ele. Para ser mais específico, vou apontar `tutorial.leomurca.xyz` para o IP do meu **VPS**: `45.76.5.44`.

### Logar no servidor via SSH 

```shell
$ ssh root@45.76.5.44
```

### Crie um usuário para gerenciar sua aplicação

Para evitar que nosso pipeline tenha acesso root ao seu servidor, criarei um usuário para gerenciar deploys chamado `tutorials`:

```shell
$ useradd -s /bin/bash -d /home/tutorials -m tutorials
```

Depois disso, logue como o usuário criado:

```shell
$ su tutorials
```

Como criei o usuário chamado `tutorials`, este usuário irá hospedar vários tutoriais, então para isolarmos nossa aplicação, crie uma pasta específica para abrigar nossos arquivos de build:

```shell
$ mkdir rsync-deploy-react-app
```

## Setup da Github Action 

Agora vamos criar o `.github/workflows/deploy.yml` para definir as etapas do pipeline. Primeiro, adicione uma label para o fluxo de trabalho e quando ele deve ser acionado:

```yml
name: Deploy

on:
  push:
    branches: [ "main" ]
```

Acima, o workflow será acionado toda vez que um novo código for **pushed** ou **merged** à branch `main` (isso também acontece para Pull Requests mergeadas à branch principal).

Em seguida, descreva um novo workflow que vamos nomear como `build-and-deploy` para lidar com todas as etapas para fazer o build e o deploy de nossa aplicação:

```yml
jobs:
  build-and-deploy:

    runs-on: ubuntu-latest

    env:
      SSH_KEY: ${{secrets.SSH_KEY}}
    
    ...

``` 

A `SSH_KEY: ${{secrets.SSH_KEY}}` faz referência a [Github Secret](https://docs.github.com/en/actions/security-guides/encrypted-secrets) que é permitido fazer login em nosso servidor. É importante mencionar que devemos adicionar o secrete às configurações do nosso repositório.

Além disso, para evitar problemas ao autenticar em seu servidor usando ssh, **use chaves geradas por RSA para autenticar em vez de chaves Ed25519**. Para mais detalhes sobre isso, verifique este documento sobre  [como gerar uma nova chave SSH](https://docs.github.com/pt/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent).

Depois, vamos começar a definir os passos reais a serem executados:

```yml
    ...
    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js 16
      uses: actions/setup-node@v3
      with:
        node-version: 16
        cache: 'npm'
    ...
```

Essas primeiras etapas basicamente definirão qual versão do [NodeJS](https://nodejs.org/en/) será usada em nosso pipeline.

E agora, um passo muito importante é adicionar os comandos que realmente serão executados em nosso workflow, preste atenção neles:

```yml
    ...
    - run: mkdir ~/.ssh
    - run: 'echo "$SSH_KEY" >> ~/.ssh/id_rsa_tutorials'
    - run: chmod 400 ~/.ssh/id_rsa_tutorials
    - run: echo -e "Host tutorials\n\tUser tutorials\n\tHostname 45.76.5.44\n\tIdentityFile ~/.ssh/id_rsa_tutorials\n\tStrictHostKeyChecking No" >> ~/.ssh/config
    - run: npm install
    - run: npm run build
    ...
```

As configurações acima nós basicamente:
- Copiamos a `SSH_KEY` para um arquivo;
- Criamos uma configuração ssh para nosso servidor usando a chave criada anteriormente;
- Baixamos as dependências do aplicativo e gere os arquivos de compilação para serem copiados para o nosso servidor.

Para tornar as configurações do ssh mais legíveis, verifique o trecho de código abaixo:
```shell
Host tutorials
  User tutorials
  Hostname 45.76.5.44
  IdentityFile  ~/.ssh/id_rsa_tutorials
  StrictHostKeyChecking No
```

### Usando rsync para fazer o deploy no servidor

E, finalmente, adicione o comando rsync para sincronizar os arquivos da pasta `build/` para o nosso servidor:

```yml
...
- run: rsync -avz --progress build/ tutorials:/home/tutorials/rsync-deploy-react-app --delete
...
```

O significado de cada flag utilizada são:
- `-a`: É uma maneira rápida de dizer que você quer recursão e quer preservar quase tudo (com -H sendo uma omissão notável);
- `-v` (`-verbose`): Esta opção aumenta a quantidade de informações que o daemon registra durante sua fase de inicialização.
- `-z` (`-compress`): comprime os dados do arquivo à medida que são enviados para a máquina de destino, o que reduz a quantidade de dados sendo transmitidos -- algo que é útil em uma conexão lenta.
- `--progress`: Esta opção diz ao rsync para imprimir informações mostrando o progresso da transferência. Isso dá a um usuário entediado algo para assistir.
- `--delete`: Diz ao rsync para excluir arquivos estranhos do lado receptor (aqueles que não estão no lado remetente), mas apenas para os diretórios que estão sendo sincronizados.

Para obter mais detalhes sobre todas as opções do `rsync`, consulte sua [man page](https://linux.die.net/man/1/rsync).

### Arquivo completo `.github/workflows/deploy.yml`

```yml
name: Deploy 

on:
  push:
    branches: [ "main" ]

jobs:
  build-and-deploy:

    runs-on: ubuntu-latest

    env:
      SSH_KEY: ${{secrets.SSH_KEY}}

    steps:
    - uses: actions/checkout@v3
    - name: Use Node.js 16
      uses: actions/setup-node@v3
      with:
        node-version: 16
        cache: 'npm'
    - run: mkdir ~/.ssh
    - run: 'echo "$SSH_KEY" >> ~/.ssh/id_rsa_tutorials'
    - run: chmod 400 ~/.ssh/id_rsa_tutorials
    - run: echo -e "Host tutorials\n\tUser tutorials\n\tHostname 45.76.5.44\n\tIdentityFile ~/.ssh/id_rsa_tutorials\n\tStrictHostKeyChecking No" >> ~/.ssh/config
    - run: npm install
    - run: npm run build
    - run: rsync -avz --progress build/ tutorials:/home/tutorials/rsync-deploy-react-app --delete
```

É isso! Altere algum código, envie-o para o branch principal e veja a mágica acontecendo!

![Captura de tela da action no Github](/img/how-to-deploy-react-applications-using-github-actions-+-rsync/github-action-screenshot-3.webp)

Além disso, se você quiser obter mais detalhes sobre as etapas da ação, verifique as [ações executadas](https://github.com/leomurca/rsync-deploy-react-app/actions) durante este artigo.

**Simples, rápido e seguro**, esses são os principais benefícios de usar o fluxo de trabalho mencionado neste tutorial. É realmente um alívio ter esse tipo de ferramenta no meio de tantas soluções inchadas.

Se você tiver alguma dúvida ou assunto para falar, por favor, [fale comigo](/contato)!
