#!/bin/sh

init_pipeline.pl LongMult_conf.pm -pipeline_url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -hive_force_init 1

runWorker.pl -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -analyses_pattern 1 -debug 1

runWorker.pl -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -job_id 10 -debug 1
runWorker.pl -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -job_id 11 -debug 1

db_cmd.pl  -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -sql 'DELETE FROM job WHERE job_id=10'
db_cmd.pl  -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -sql 'UPDATE job SET semaphore_count=semaphore_count-1 WHERE job_id=9'

runWorker.pl -url mysql://ensadmin:ensembl@127.0.0.1/lg4_long_mult -job_id 2 -force 1 -debug 1
