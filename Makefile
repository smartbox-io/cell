.PHONY: all build spec brakeman

all: build spec brakeman

build:
	docker build -t cell .

spec:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rspec

rubocop:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec rubocop -D

brakeman:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle exec brakeman -zA

update:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle update
