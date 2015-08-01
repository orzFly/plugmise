PATH := ./node_modules/.bin:${PATH}

.PHONY: init clean build dist publish test

init:
	npm install

clean:
	rm -f lib/*.js

build:
	coffee -o lib/ -c lib/

dist: clean init test build

publish: dist
	npm publish

test:
	./node_modules/.bin/mocha --compilers coffee:coffee-script/register --require test/support/env -- test/*.test.coffee