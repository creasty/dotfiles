section "Configure redis"
sed -ie 's/^daemonize no/daemonize yes/' /usr/local/etc/redis.conf
