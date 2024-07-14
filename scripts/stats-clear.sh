#!/bin/bash

docker exec -it tagd rm -r "target/benchbase-postgres/results/"

docker exec -it tagd psql -U postgres -d benchbase -c "select pg_stat_statements_reset();"