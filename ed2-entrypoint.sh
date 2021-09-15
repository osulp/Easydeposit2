#!/bin/bash

sleep_secs=300
export PATH="/data/bin:/usr/local/deploy-rails/bin:$PATH"
rm -f tmp/pids/server.pid

timestamp=`date +'%Y-%m-%d %H:%M:%S'`
echo "[$timestamp]: Starting Easydeposit2 initialization"
echo "  image: $IMAGE"
echo "  rails:"
echo "    env: $RAILS_ENV"
echo "    max threads: $RAILS_MAX_THREADS"
echo "    log to stdout: $RAILS_LOG_TO_STDOUT"
echo "    serve static files: $RAILS_SERVE_STATIC_FILES"
echo "    cache store url: $RAILS_CACHE_STORE_URL"
echo "  osu api uri: ${OSU_API_URL}${API_ROUTE}"
echo "  redis uri: $ED2_REDIS_HOST:$ED2_REDIS_PORT"
echo "  honeycomb dataset: $HONEYCOMB_DATASET"
echo "  CAS:"
echo "    base url: $ED2_CAS_BASE_URL"
echo "    validate url: $ED2_CAS_VALIDATE_URL"
echo "  app database: "
echo "    $ED2_DB_USERNAME@$ED2_DB_HOST [$ED2_DB]"

# Run database migrations
timestamp=`date +'%Y-%m-%d %H:%M:%S'`
echo "[$timestamp]: Running database migrations"
/usr/local/bin/bundle exec rails db:migrate

# Compile static assets
timestamp=`date +'%Y-%m-%d %H:%M:%S'`
echo "[$timestamp] Precompiling assets ($RAILS_ENV)"
RAILS_ENV=$RAILS_ENV SECRET_KEY_BASE=temporary bundle exec rake assets:precompile

# Start rails
timestamp=`date +'%Y-%m-%d %H:%M:%S'`
echo "[$timestamp]: Starting Rails ($RAILS_ENV)"
/usr/local/bin/bundle exec puma -C /data/config/puma/${RAILS_ENV}.rb


# Sleep loop
# Every $sleep_secs seconds, display the number of non-shell processes,
# the PID of postmaster and the handle server and number of established
# connections
sleep 5
while `true`; do
   timestamp=`date +'%Y-%m-%d %H:%M:%S'`
   nproc=`ps ax | grep -v grep | grep -v bash | wc -l`
   estab=`netstat -an | grep ESTAB | grep -v grep | wc -l`

   echo "[$timestamp] nproc=$nproc conn=$estab"
   sleep $sleep_secs
done
