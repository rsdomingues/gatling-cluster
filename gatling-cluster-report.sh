#!/bin/bash
##################################################################################################################
#Gatling scale out/cluster run script:
#Before running this script some assumptions are made:
#1) Public keys were exchange inorder to ssh with no password promot (ssh-copy-id on all remotes)
#2) Check  read/write permissions on all folders declared in this script.
#3) Gatling installation (GATLING_HOME variable) is the same on all hosts
#4) Assuming all hosts has the same user name (if not change in script)
##################################################################################################################

#Assuming same user name for all hosts
USER_NAME='toor'

#Remote hosts list
HOSTS=(10.211.55.7)

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

for HOST in "${HOSTS[@]}"
do
  echo "Gathering result file from host: $HOST"
  #ssh -n -f $USER_NAME@$HOST "sh -c 'ls -t $GATLING_REPORT_DIR | head -n 1 | xargs -I {} mv ${GATLING_REPORT_DIR}{} ${GATLING_REPORT_DIR}report'"
  scp $USER_NAME@$HOST:${GATLING_REPORT_DIR}report/simulation.log ${GATHER_REPORTS_DIR}simulation-$HOST.log
done

mv $GATHER_REPORTS_DIR $GATLING_AGGREGATION_DIR
echo "Aggregating simulations"
$GATLING_RUNNER -ro reports

#using macOSX
open ${GATLING_REPORT_DIR}reports/index.html

#using ubuntu
#google-chrome ${GATLING_REPORT_DIR}reports/index.html