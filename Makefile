#!/usr/bin/make -f

.PHONY: help init build deploy clean serve

help:
	$(info make init|deploy|build|clean|serve)

init:
	echo "Making $@"; \

build: 
	echo "Making $@"
	$(shell ./scripts/generate-html-articles.sh)

deploy:
	echo "Making $@"

clean:
	echo "Making $@"

serve:
	python -m http.server --directory src
