#!/usr/bin/make -f

.PHONY: help init build deploy clean serve

BLOG_REMOTE=rootleo:/srv/www/leomurca.xyz

help:
	$(info make init|deploy|build|clean|serve)

init:
	echo "Making $@"; \

build: clean
	echo "Making $@"
	hugo --minify

deploy: build
	echo "Making $@"
	rsync -rLtvz public/ $(BLOG_REMOTE)

clean:
	echo "Making $@"
	rm -rf public/

prod:
	python -m http.server --directory public

dev:
	hugo server
