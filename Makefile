SPEC ?= spec

.PHONY: all build spec brakeman

all: build spec brakeman

build:
	docker build -t cell .

run:
	docker run --rm -v `pwd`:/cell -it cell:latest bash

spec:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rspec $(SPEC)

rubocop:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rubocop -D

brakeman:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec brakeman -zAI

update:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle update
