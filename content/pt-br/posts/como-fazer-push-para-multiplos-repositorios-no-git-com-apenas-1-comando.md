---
title: "Como fazer push para múltiplos repositórios no git com apenas 1 comando"
date: 2022-10-11T16:51:53-03:00
description: "Aprenda como fazer push para múltiplos repositórios no git com apenas 1 comando (terminal)."
featured_image: "/img/how-to-push-to-multiple-git-remotes-with-one-command/featured_image.webp"
draft: false
---

Repositories used for the tutorial: 
- [gh-remote](https://github.com/leomurca/gh-remote);
- [gl-remote](https://gitlab.com/leomurca/gl-remote.git).

## TL;DR
- Clone the primary repository ([gh-remote](https://github.com/leomurca/gh-remote));

```shell
$ git clone git@github.com:leomurca/gh-remote.git
```

- Add the secondary remote ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) to the cloned folder;

```shell
$ git remote add gitlab git@gitlab.com:leomurca/gl-remote.git
```

- Add a third remote that will be used to push to all the remotes at the same time. For conveniece, we'll name it as `all`. Also, as the url, we'll use the value `fetch-not-supported`;

```shell
$ git remote add all fetch-not-supported
```

- Add the remotes that you want your code to be pushed when `git push all <BRANCH>` is executed;

```shell
$ git remote set-url --add --push all git@gitlab.com:leomurca/gl-remote.git
$ git remote set-url --add --push all git@github.com:leomurca/gh-remote.git
```

- And finally to test if it is working, change some code locally, run the command below and check your both remotes (Be aware of the branch that you are using. In our example, we are using the `main` branch).

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

## Introduction

This tutorial is pretty straightforward on how to simplify the syncronization across multiple git remotes, I recommend to save it to your bookmark if you forget any steps.

## Why to push to multiple git remotes?

The main use case for pusing to multiple git remotes is to syncronize your changes among all the mirrors used as redundancy for your project. If that is your case (or event if it isn't but you want to learn something new), let's dive in.

## Adding multiple remotes

First of all, you need to have the primary git repository cloned to your local machine. You can also start by creating a local repository and then pushing to a remote, but for this tutorial, we'll keep it simple. So, let's clone our primary repository, which in this case, is the [gh-remote](https://github.com/leomurca/gh-remote).

### Cloning the repo (with the primary remote)

```shell
$ git clone git@github.com:leomurca/gh-remote.git
```

After cloning it, check the default remote assigned to it.

```shell
$ git remote -v
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

### Adding a second remote

You can notice that the default remote name assigned to the primary repo was `origin`, but you can also change it in the future. Right, now let's just add the second remote ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) to the cloned folder and then list all the remotes afterwards;

```shell
$ git remote add gitlab git@gitlab.com:leomurca/gl-remote.git
$ git remote -v
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

### Adding a third remote (push only)
We'll add a third remote that will be used to push to all the remotes at the same time. For conveniece, we'll name it as `all`. Also, as the url, we'll use the value `fetch-not-supported`. After that, list the remotes.

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

And finally, we'll add the remotes that we want our code to be pushed when `git push all <BRANCH>` is executed;

```shell
$ git remote set-url --add --push all git@gitlab.com:leomurca/gl-remote.git
$ git remote set-url --add --push all git@github.com:leomurca/gh-remote.git
```

## List all remotes

Let's see the final result listing all the remotes added before.

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

## Pushing to multiple remotes

And now that everything is set up, let's test if it is working: change some code locally, run the command below and check your both remotes (Be aware of the branch that you are using. In our example, we are using the `main` branch).

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

That's all! Enjoy your new git configuration.

## Extra

Do want to fetch from multiple remotes? Just execute `git fetch --all`.
