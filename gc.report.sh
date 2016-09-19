#!/bin/bash
##################################################################################################################
#Gatling scale out/cluster run script:
#Before running this script some assumptions are made:
#1) Public keys were exchange inorder to ssh with no password promot (ssh-copy-id on all remotes)
#2) Check  read/write permissions on all folders declared in this script.
#3) Gatling installation (GATLING_HOME variable) is the same on all hosts
#4) Assuming all hosts has the same user name (if not change in script)
##################################################################################################################

usage="usage: $(basename "$0") username hostlist"

if [ "$#" -lt 2 ] ; then
    echo $usage
    exit 0
fi

#Assuming same user name for all hosts
USER_NAME=$1

#Remote hosts list
HOSTS=($2) #10.211.55.7

#Assuming all Gatling installation in same path (with write permissions)
GATLING_HOME=/gatling
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh

#No need to change this
GATLING_REPORT_DIR=$GATLING_HOME/results/
GATLING_AGGREGATION_DIR=$GATLING_HOME/results/reports
GATHER_REPORTS_DIR=$GATLING_HOME/report/

echo "Cleaning previous runs from localhost"

rm -rf $GATLING_AGGREGATION_DIR
rm -rf $GATHER_REPORTS_DIR
rm -rf $GATLING_REPORT_DIR
mkdir $GATHER_REPORTS_DIR
mkdir $GATLING_REPORT_DIR
mkdir $GATLING_AGGREGATION_DIR

REMOTE_GATTLING_RUNNING="y"

while [ "$REMOTE_GATTLING_RUNNING" != "n" ] ; do
	#Starts of thinking that all process are finished
	REMOTE_GATTLING_RUNNING="n"

	for HOST in "${HOSTS[@]}" ; do
		echo "Checking process execuiton in: $HOST"
		RESPONSE=$(ssh $USER_NAME@$HOST "pgrep gatling")
		echo "[$RESPONSE]"
		if [ ! -z "$RESPONSE" ]; then
			#if one instance is not finished, the process must wait
		    echo "Process is running on $HOST"
		    REMOTE_GATTLING_RUNNING="y"
		else
		    echo "Process is not running on $HOST"
		fi
	done

	if [ "$REMOTE_GATTLING_RUNNING" != "n" ]; then
		echo "There are still gatling clients running, waint 30s and trying again"
		sleep 30s
	else
		echo "All executors appear to be done, continuing process"
	fi
done

for HOST in "${HOSTS[@]}"
do
  echo "Gathering result file from host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'ls -t $GATLING_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REPORT_DIR}{} ${GATLING_REPORT_DIR}report'"
  scp $USER_NAME@$HOST:${GATLING_REPORT_DIR}report/simulation.log ${GATHER_REPORTS_DIR}simulation-$HOST.log
done

mv $GATHER_REPORTS_DIR $GATLING_AGGREGATION_DIR
echo "Aggregating simulations"
$GATLING_RUNNER -ro reports

#using macOSX
open ${GATLING_REPORT_DIR}reports/index.html

#using ubuntu
#google-chrome ${GATLING_REPORT_DIR}reports/index.html