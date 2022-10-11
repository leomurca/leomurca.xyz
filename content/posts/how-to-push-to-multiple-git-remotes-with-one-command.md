---
title: "How to Push to Multiple Git Remotes With One Command"
date: 2022-10-11T16:51:53-03:00
draft: true
---

## TL;DR

- These are the 2 repositories used for this guide: [gh-remote](https://github.com/leomurca/gh-remote) and [gl-remote](https://gitlab.com/leomurca/gl-remote.git). Also, the primary repository, which was the one cloned locally, is the [gh-remote](https://github.com/leomurca/gh-remote).

- Clone the primary repository ([gh-remote](https://github.com/leomurca/gh-remote));
```shell
$ git clone git@github.com:leomurca/gh-remote.git
```

- List all remotes added to your repo;
```shell
$ git remote -v
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

- Add the secondary remote ([gl-remote](https://gitlab.com/leomurca/gl-remote.git)) to the cloned folder and list all the remotes afterwards;
```shell
$ git remote add gitlab git@gitlab.com:leomurca/gl-remote.git

```

```shell
$ git remote -v
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

- Add a third remote that will be used to push to all the remotes at the same time. For conveniece, we'll name it as `all`. Also, as the url, we'll use the value `fetch-not-supported`. Then, list the remotes;

```shell
$ git remote add all fetch-not-supported
```
```shell
$ git remote -v
all     fetch-not-supported (fetch)
all     fetch-not-supported (push)
gitlab  git@gitlab.com:leomurca/gl-remote.git (fetch)
gitlab  git@gitlab.com:leomurca/gl-remote.git (push)
origin  git@github.com:leomurca/gh-remote.git (fetch)
origin  git@github.com:leomurca/gh-remote.git (push)
```

- And finally add the remotes that you want your code to be pushed when `git push all <BRANCH>` is executed;
```shell
$ git remote set-url --add --push all git@gitlab.com:leomurca/gl-remote.git
$ git remote set-url --add --push all git@github.com:leomurca/gh-remote.git
```

- See all the remotes added;
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

- Then, to test if it is working, change some code locally, run the command below and check your both remotes (Be aware of the branch that you are using. In our example, we are using the `main` branch).
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