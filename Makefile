.PHONY: all build spec brakeman

all: build spec brakeman

build:
	docker build -t cell .

spec:
	docker run --rm -v `pwd`:/cell -it cell:latest rspec

brakeman:
	docker run --rm -v `pwd`:/cell -it cell:latest brakeman -zA

update:
	docker run --rm -v `pwd`:/cell -it cell:latest bundle update
