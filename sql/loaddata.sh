export PGPASSWORD="password"
psql -h localhost -U postgres -f clubdata.sql -d practice -x -q > log.txt
exit $?