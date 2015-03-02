FROM dockerfile/dart
MAINTAINER Axel Christ <adracus@gmail.com>

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

COPY . /usr/src/app
RUN pub get

EXPOSE 8080
CMD ["dart", "bin/server.dart", "--port 8080"]