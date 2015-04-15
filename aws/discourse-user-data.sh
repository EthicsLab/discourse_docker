#!/bin/bash

# Abort our setup if anything goes wrong.
set -e

/usr/bin/apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
echo "deb https://get.docker.io/ubuntu docker main" > /etc/apt/sources.list.d/docker.list
/usr/bin/apt-get update -q
/usr/bin/apt-get install -qy lxc-docker python-pip curl git nfs-common

sed -i '/^NEED_STATD/cNEED_STATD=no/' /etc/default/nfs-common
sed -i '/^NEED_GSSD/cNEED_GSSD=no/' /etc/default/nfs-common

service rpcbind restart

mkdir -p /shared/uploads

/usr/bin/pip install boto args

curl https://s3-us-west-2.amazonaws.com/ethicslab-support/ddbconfig.py > /usr/local/bin/ddbconfig
chmod 0755 /usr/local/bin/ddbconfig

APP=discourse
DOCKER_IMAGE_URL=https://s3-us-west-2.amazonaws.com/ethicslab-support/discourse-docker-image.tar.gz
DOCKER_IMAGE_HASH=43845baa9f06

/usr/local/bin/ddbconfig -a $APP > /tmp/env

until docker version; do
   echo 'waiting for docker'
   sleep 1
done

NFS_SERVER_IP=$(host nfs-server.ethicslab.org | cut -d" " -f4)

mount -t nfs -o proto=tcp,port=2049 $NFS_SERVER_IP:/shared/uploads /shared/uploads

DOCKER0_IP=$(ifconfig docker0 | egrep -o 'inet addr:([^ ]+)' | cut -d: -f2)

curl -sS $DOCKER_IMAGE_URL | gunzip -f | docker load

# Run our app container dockerhub is hosting
docker run -d --restart=always --env-file /tmp/env -e LANG=en_US.UTF-8 -e RAILS_ENV=production -e UNICORN_WORKERS=3 -e UNICORN_SIDEKIQS=1 -e RUBY_GC_MALLOC_LIMIT=40000000 -e RUBY_HEAP_MIN_SLOTS=800000 -e DISCOURSE_DB_SOCKET="" -e DOCKER_HOST_IP=$DOCKER0_IP -d --name app -t -v /shared/uploads:/shared/uploads -p 80:80 $DOCKER_IMAGE_HASH /sbin/boot

