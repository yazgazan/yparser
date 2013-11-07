
MOCHA=	./node_modules/mocha/bin/mocha

all:	build test

build:
	coffee -o lib/ -c srcs/*.coffee
	coffee -o test/ -c test/*.coffee

clean:
	rm -rvf lib/*.js *.js test/*.js

test:
	$(MOCHA) -R spec

.PHONY: all build clean test

