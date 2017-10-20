SPEC ?= spec

.PHONY: all build spec models requests lib rubocop brakeman update

all: build spec brakeman

build:
	docker build -t cell .

run:
	docker run --rm -v `pwd`:/cell -it cell:latest sh

routes:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rake routes

spec:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rspec $(SPEC)

models:
	docker run --rm -e COVERAGE=models -v `pwd`:/cell -it cell:latest bundle exec rspec spec/models

requests:
	docker run --rm -e COVERAGE=requests -v `pwd`:/cell -it cell:latest bundle exec rspec spec/requests

lib:
	docker run --rm -e COVERAGE=lib -v `pwd`:/cell -it cell:latest bundle exec rspec spec/lib

rubocop:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rubocop -D

brakeman:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec brakeman -zAI

update:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle update
