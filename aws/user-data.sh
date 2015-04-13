#!/bin/bash

# Abort our setup if anything goes wrong.
set -e

/usr/bin/apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
echo "deb https://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list
/usr/bin/apt-get update -q
/usr/bin/apt-get install -qy lxc-docker python-pip curl git

/usr/bin/pip install boto args

curl https://s3-us-west-2.amazonaws.com/ethicslab-support/ddbconfig.py > /usr/local/bin/ddbconfig
chmod 0755 /usr/local/bin/ddbconfig

DOCKERHUB_USER=gtethicslab
DOCKERHUB_PASSWORD=\$mgF5rN53BiIw.]J
DOCKERHUB_EMAIL=ethicslab@georgetown.edu
DOCKERHUB_VERSION=latest
APP=discourse

/usr/local/bin/ddbconfig -a $APP > /tmp/env

until docker version; do
   echo 'waiting for docker'
   sleep 1
done

DOCKER0_IP=$(ifconfig docker0 | egrep -o 'inet addr:([^ ]+)' | cut -d: -f2)

# Log into dockerhub
docker login -u $DOCKERHUB_USER -p $DOCKERHUB_PASSWORD -e $DOCKERHUB_EMAIL

# Run our app container dockerhub is hosting
docker run -d --restart=always --env-file /tmp/env -e LANG=en_US.UTF-8 -e RAILS_ENV=production -e UNICORN_WORKERS=3 -e UNICORN_SIDEKIQS=1 -e RUBY_GC_MALLOC_LIMIT=40000000 -e RUBY_HEAP_MIN_SLOTS=800000 -e DISCOURSE_DB_SOCKET="" -e DOCKER_HOST_IP=$DOCKER0_IP -d -v /var/discourse/shared:/shared --name app -t -p 80:80 "$DOCKERHUB_USER/$(echo $APP | sed 's/_/-/g'):$DOCKERHUB_VERSION" /sbin/boot
