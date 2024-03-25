---
title: "Como fazer push para múltiplos repositórios no git com apenas 1 comando"
date: 2022-10-11T16:51:53-03:00
lastmod: 2024-03-24
description: "Aprenda como fazer push para múltiplos repositórios no git com apenas 1 comando (terminal)."
featured_image: "/img/how-to-push-to-multiple-git-remotes-with-one-command/featured_image.webp"
draft: false
---

![Rosas amarelas](/img/how-to-push-to-multiple-git-remotes-with-one-command/cover-image-1.webp)

Repositório utilizados neste tutorial:
- [gh-remote](https://github.com/leomurca/gh-remote);
- [gl-remote](https://gitlab.com/leomurca/gl-remote.git).

## TL;DR
- Clone repositório primário ([gh-remote](https://github.com/leomurca/gh-remote));

```shell
$ git clone git@github.com:leomurca/gh-remote.git
```

- Adicione o remote do repositório secundário ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) ao diretório clonado;

```shell
$ git remote add gitlab git@gitlab.com:leomurca/gl-remote.git
```

- Adicione um terceiro remote que será utilizado para fazer o push para todos os remotes ao mesmo tempo. Por conveniência, vamos nomeá-lo como `all`. Além disso, nomeie sua url como `fetch-not-supported`;

```shell
$ git remote add all fetch-not-supported
```

- Adicione os remotes que você deseja que seu código seja enviado quando `git push all <BRANCH>` for executado;

```shell
$ git remote set-url --add --push all git@gitlab.com:leomurca/gl-remote.git
$ git remote set-url --add --push all git@github.com:leomurca/gh-remote.git
```

- E, finalmente, para testar se está funcionando, altere algum código localmente, execute o comando abaixo e verifique seus dois remotes (esteja ciente da branch que você está usando. Em nosso exemplo, estamos usando o branch `main`).

```shell
$ git push all main
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Writing objects: 100% (3/3), 275 bytes | 91.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To gitlab.com:leomurca/gl-remote.git
   584aa2b..1a17aa1  main -> main
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (6/6), 512 bytes | 85.00 KiB/s, done.
Total 6 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:leomurca/gh-remote.git
   7e0fb66..1a17aa1  main -> main
```

---

## Introdução

Este tutorial é bem direto sobre como simplificar a sincronização entre vários remotes git, recomendo salvá-lo em seus favoritos caso esqueça alguma etapa.

## Por que fazer o psuh para múltiplos remotes git?

O principal caso de uso para usar vários remotes git é sincronizar suas alterações entre todos os espelhos usados como redundância para seu projeto. Se esse for o seu caso (ou mesmo se não for, mas você quer aprender algo novo), vamos mergulhar de cabeça.

## Adicionando múltiplos remotes

Primeiro de tudo, você precisa ter o repositório git primário clonado em sua máquina local. Você também pode começar criando um repositório local e, em seguida, enviar para um remoto, mas para este tutorial, vamos simplificar. Então, vamos clonar nosso repositório primário, que no caso é o [gh-remote](https://github.com/leomurca/gh-remote).

### Clonando o repositório (com o remote primário)

```shell
$ git clone git@github.com:leomurca/gh-remote.git
```

Depois de cloná-lo, verifique o remote padrão atribuído a ele.

```shell
$ git remote -v
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

### Adicionando um segundo remote

You can notice that the default remote name assigned to the primary repo was `origin`, but you can also change it in the future. Right, now let's just add the second remote ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) to the cloned folder and then list all the remotes afterwards;

Você pode notar que o nome padrão do remote atribuído ao repositório primário era `origin`, mas também pode alterá-lo no futuro. Certo, agora vamos apenas adicionar o segundo remote ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) na pasta clonada e depois listar todos os controles remotos;

```shell
$ git remote add gitlab git@gitlab.com:leomurca/gl-remote.git
$ git remote -v
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

### Adicionando um terceiro remote (somente push)
Adicionaremos um terceiro remote que será usado para enviar para todos os remotes ao mesmo tempo. Por conveniência, vamos nomeá-lo como `all`. Além disso, como url, usaremos o valor `fetch-not-supported`. Depois disso, liste os remotes.

```shell
$ git remote add all fetch-not-supported
$ git remote -v
all     fetch-not-supported (fetch)
all     fetch-not-supported (push)
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

E, finalmente, adicionaremos os remotes que queremos que nosso código seja enviado quando `git push all <BRANCH>` for executado;

```shell
$ git remote set-url --add --push all git@gitlab.com:leomurca/gl-remote.git
$ git remote set-url --add --push all git@github.com:leomurca/gh-remote.git
```

## Liste todos os remotes 

Vamos ver o resultado final listando todos os remotes adicionados anteriormente.

```shell
$ git remote -v
all     fetch-not-supported (fetch)
all     git@gitlab.com:leomurca/gl-remote.git (push)
all     git@github.com:leomurca/gh-remote.git (push)
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

## Fazendo push para múltiplos remotes 

And now that everything is set up, let's test if it is working: change some code locally, run the command below and check your both remotes (Be aware of the branch that you are using. In our example, we are using the `main` branch).

E agora que tudo está configurado, vamos testar se está funcionando: altere algum código localmente, execute o comando abaixo e verifique seus dois remotes (Fique atento à branch que você está usando. Em nosso exemplo, estamos usando a branch main `main `).

```shell
$ git push all main
Enumerating objects: 5, done.
Counting objects: 100% (5/5), done.
Writing objects: 100% (3/3), 275 bytes | 91.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
To gitlab.com:leomurca/gl-remote.git
   584aa2b..1a17aa1  main -> main
Enumerating objects: 8, done.
Counting objects: 100% (8/8), done.
Delta compression using up to 10 threads
Compressing objects: 100% (2/2), done.
Writing objects: 100% (6/6), 512 bytes | 85.00 KiB/s, done.
Total 6 (delta 0), reused 0 (delta 0), pack-reused 0
To github.com:leomurca/gh-remote.git
   7e0fb66..1a17aa1  main -> main
```

Isso é tudo! Aproveite sua nova configuração git.

## Extra

Quer fazer um fetch de vários remotes? Basta executar `git fetch --all`.
