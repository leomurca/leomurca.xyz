#!/usr/bin/make -f

include config

.PHONY: help init build deploy clean serve

ARTICLES_SRC ?= articles

ARTICLES = $(shell git ls-tree HEAD --name-only -- $(ARTICLES_SRC)/*.md 2>/dev/null)

help:
	$(info make init|deploy|build|clean|serve)

init:
	echo "Making $@"

build: 
	echo "Making $@"

deploy:
	echo "Making $@"

clean:
	echo "Making $@"

serve:
	python -m http.server --directory src

