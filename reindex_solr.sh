#!/usr/bin/bash

docker exec $WEB_CONTAINER bundle exec rails runner "ActiveFedora::Base.reindex_everything"