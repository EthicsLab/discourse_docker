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

APP=discourse

/usr/local/bin/ddbconfig -a $APP > /tmp/env

mkdir /var/docker
cd /var/docker
git clone http://github.com/ethicslab/discourse_docker .
git checkout dev

cp containers/app.yml.pre containers/app.yml
sed -r 's/^([^=]+)=(.*)$/ \1: \2/g' /tmp/env >> containers/app.yml

./launcher bootstrap app
./launcher start app

