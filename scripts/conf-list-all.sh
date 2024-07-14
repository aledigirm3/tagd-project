#!/bin/bash

# Mostra i nomi di tutti i file di configurazione benchbase.

docker exec tagd sh -c 'ls /root/benchbase-2023/target/benchbase-postgres/config/postgres'