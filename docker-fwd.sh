#!/bin/sh
mkdir -p /var/run/postgresql/
rm -f /var/run/postgresql/.s.PGSQL.5432
socat UNIX-LISTEN:/var/run/postgresql/.s.PGSQL.5432,fork TCP:db:5432 &
