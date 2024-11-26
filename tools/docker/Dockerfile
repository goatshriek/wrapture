# ruby:3.3.6-alpine3.20
FROM ruby@sha256:caeab43b356463e63f87af54a03de1ae4687b36da708e6d37025c557ade450f8

# copy the build-necessary source into the container
WORKDIR /usr/src/wrapture
COPY bin ./bin
COPY lib ./lib
COPY sig ./sig
COPY Gemfile wrapture.gemspec ./

# set up the environment for the build
RUN apk update \
      && apk add --no-cache --virtual build-dependencies build-base \
      && bundle install \
      && gem build --output wrapture.gem wrapture.gemspec \
      && gem install wrapture.gem \
      && apk del build-dependencies \
      && addgroup -S wrapture \
      && adduser -S wrapture -G wrapture

# set the user to wrapture
WORKDIR /home/wrapture
USER wrapture
