#!/usr/bin/env bash

# -e: exit as soon as a command exit with a non-zero status code
# -u: prevent from any undefined variable
# -o pipefail: force pipelines to fail on the first non-zero status code
set -euo pipefail
# Avoid using space as a separator (default IFS=$' \t\n')
IFS=$'\n\t'

for i in {30..0}
do
    if nc -z localhost 15672
    then
        break
    fi

    echo "RabbitMQ init process in progress..."
    sleep 1
done

if [[ "$i" = 0 ]]
then
    >&2 echo "RabbitMQ init process failed."

    exit 1
fi

if ! [[ -d /etc/rabbitmq ]]
then
    mkdir /etc/rabbitmq
fi

if [[ -f /etc/rabbitmq/rabbitmqadmin ]]
then
    echo "RabbitMQ is already configured."

    exit 0
fi

wget -O /etc/rabbitmq/rabbitmqadmin http://127.0.0.1:15672/cli/rabbitmqadmin
chmod 777 /etc/rabbitmq/rabbitmqadmin

###
## Define your vhost, queues...
##


#if ! rabbitmqctl list_vhosts | grep -q <my_vhost>
#then
#    rabbitmqctl add_vhost <my_vhost> >/dev/null
#    rabbitmqctl set_permissions -p <my_vhost> guest ".*" ".*" ".*" >/dev/null
#fi
#
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare exchange name=<exchange_name> type=direct durable=true
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare exchange name=unroutable type=fanout durable=true
#
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare policy name=AE pattern=<matching exchange> apply-to="exchanges" definition='{"alternate-exchange": "unroutable"}'
#
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare queue name="unroutable" durable=true auto_delete=false
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare binding source="unroutable" destination="unroutable" routing_key=""
#
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare queue name="<my queue>" durable=true auto_delete=false
#/etc/rabbitmq/rabbitmqadmin --vhost=<my_vhost> declare binding source="<my source>" destination="<my queue>" routing_key="<my routing key>"
