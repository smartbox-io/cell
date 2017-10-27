FROM ruby:2
ENV BUILD_PACKAGES="build-essential"
RUN apt-get update -qq && apt-get install -y $BUILD_PACKAGES && rm -rf /var/lib/apt/lists/*
RUN mkdir /cell
WORKDIR /cell
ADD Gemfile /cell/Gemfile
ADD Gemfile.lock /cell/Gemfile.lock
RUN bundle install
RUN apt-get remove --purge -y $BUILD_PACKAGES && apt-get autoremove --purge -y && apt-get -y clean
ENV PATH "/cell/bin:${PATH}"
ADD . /cell
