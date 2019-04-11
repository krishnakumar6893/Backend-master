#set base image
FROM ubuntu:14.04

#set working directory
WORKDIR /opt/fontli

#adding contents to the container
ADD . /opt/fontli

#setup environment
RUN apt update && apt install make zlib1g-dev g++ ruby ruby-dev -y

#install bundler
RUN gem install bundler -v 1.15.4

#running bundle install
RUN bundle install
