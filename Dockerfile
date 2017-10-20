FROM ruby:alpine
RUN apk add --update build-base mariadb-dev sqlite-dev nodejs tzdata && rm -rf /var/cache/apk/*
RUN mkdir /cell
WORKDIR /cell
ADD Gemfile /cell/Gemfile
ADD Gemfile.lock /cell/Gemfile.lock
RUN bundle install
ADD . /cell
ENV PATH "/cell/bin:${PATH}"
