#!/usr/bin/make -f

.PHONY: help init build deploy clean serve

BLOG_REMOTE=rootleo:/srv/www/leomurca.xyz

help:
	$(info make init|deploy|build|clean|serve)

init:
	echo "Making $@"; \

build: clean
	echo "Making $@"
	hugo

deploy: build
	echo "Making $@"
	rsync -rLtvz public/ $(BLOG_REMOTE)

clean:
	echo "Making $@"
	rm -rf public/ 

serve:
	python -m http.server --directory public
