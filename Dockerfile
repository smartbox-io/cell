FROM ruby:2
RUN apt-get update -qq && apt-get install -y build-essential
RUN mkdir /cell
WORKDIR /cell
ADD Gemfile /cell/Gemfile
ADD Gemfile.lock /cell/Gemfile.lock
RUN bundle install
ADD . /cell
ENV PATH "/cell/bin:${PATH}"
