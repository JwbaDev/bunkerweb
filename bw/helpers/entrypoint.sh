#!/bin/bash

. /opt/bunkerweb/helpers/utils.sh

log "ENTRYPOINT" "ℹ️" "Starting BunkerWeb v$(cat /opt/bunkerweb/VERSION) ..."

# setup and check /data folder
/opt/bunkerweb/helpers/data.sh "ENTRYPOINT"

# trap SIGTERM and SIGINT
function trap_exit() {
	log "ENTRYPOINT" "ℹ️" "Catched stop operation"
	log "ENTRYPOINT" "ℹ️" "Stopping nginx ..."
	/usr/sbin/nginx -s stop
}
trap "trap_exit" TERM INT QUIT

# trap SIGHUP
function trap_reload() {
	log "ENTRYPOINT" "ℹ️" "Catched reload operation"
	if [ -f /opt/bunkerweb/tmp/nginx.pid ] ; then
		log "ENTRYPOINT" "ℹ️" "Reloading nginx ..."
		nginx -s reload
		if [ $? -eq 0 ] ; then
			log "ENTRYPOINT" "ℹ️" "Reload successful"
		else
			log "ENTRYPOINT" "❌" "Reload failed"
		fi
	else
		log "ENTRYPOINT" "⚠️" "Ignored reload operation because nginx is not running"
	fi
}
trap "trap_reload" HUP

# generate "temp" config
echo -e "IS_LOADING=yes\nSERVER_NAME=\nAPI_HTTP_PORT=${API_HTTP_PORT:-5000}\nAPI_SERVER_NAME=${API_SERVER_NAME:-bwapi}\nAPI_WHITELIST_IP=${API_WHITELIST_IP:-127.0.0.0/8}" > /tmp/variables.env
python3 /opt/bunkerweb/gen/main.py --variables /tmp/variables.env

# start nginx
log "ENTRYPOINT" "ℹ️" "Starting nginx ..."
nginx -g "daemon off;" &
pid="$!"

# wait while nginx is running
wait "$pid"
while [ -f "/opt/bunkerweb/tmp/nginx.pid" ] ; do
	wait "$pid"
done

log "ENTRYPOINT" "ℹ️" "BunkerWeb stopped"
exit 0