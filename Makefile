#!/usr/bin/make -f

.PHONY: help init build deploy clean serve

BLOG_REMOTE=rootleo:/var/www/leomurca.xyz

help:
	$(info make init|deploy|build|clean|serve)

init:
	echo "Making $@"; \

build: 
	echo "Making $@"
	$(shell ./scripts/generate-html-articles.sh)

deploy: build
	echo "Making $@"
	rsync -rLtvz src/ $(BLOG_REMOTE)

clean:
	echo "Making $@"

serve:
	python -m http.server --directory src
