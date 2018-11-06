FROM ruby:2.5.1
RUN curl --silent --location https://deb.nodesource.com/setup_9.x | bash -
RUN apt-get update -qq && \
  apt-get install -y build-essential libpq-dev mysql-client nodejs npm mailutils sendmail && \
  rm -rf /var/lib/apt/lists/*
# Necessary for bundler to properly install some gems
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
RUN mkdir /data
WORKDIR /data
ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
#RUN apt-get update && apt-get install -y yarn
#RUN apt-get remove cmdtest
RUN npm install -g yarn
RUN gem install bundler
ADD . /data
RUN yarn
RUN bundle install
EXPOSE 3000
