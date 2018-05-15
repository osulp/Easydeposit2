FROM ruby:2.5.1
RUN apt-get update -qq && \
  apt-get install -y build-essential libpq-dev
# Necessary for bundler to properly install some gems
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
RUN gem install bundler
RUN bundle install
ADD . /data
#RUN bundle exec rake assets:precompile
EXPOSE 3000
