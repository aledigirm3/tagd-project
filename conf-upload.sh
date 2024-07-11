#!/bin/bash

CONF_NAME=$1

if [ -z "$CONF_NAME" ]; then
    echo "Usage: $0 <config-name>"
    exit 1
fi

docker cp "$CONF_NAME" tagd:/root/benchbase-2023/target/benchbase-postgres/config/postgres/ 