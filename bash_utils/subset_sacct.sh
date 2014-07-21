jobids=`sacct | grep $1 | tr -s ' '| cut -f1 -d  ' ' | tr "\n" ","`;sacct -j $jobids --format=jobid,jobname,state,maxRSS,elapsed
