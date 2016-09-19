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
GATLING_SIMULATIONS_DIR=$GATLING_HOME/user-files/simulations
GATLING_RUNNER=$GATLING_HOME/bin/gatling.sh

#Change to your simulation class name
SIMULATION_NAME='computerdatabase.BasicSimulation'

#No need to change this
GATLING_REPORT_DIR=$GATLING_HOME/results/
GATHER_REPORTS_DIR=/gatling/reports/

echo "Starting Gatling cluster run for simulation: $SIMULATION_NAME"

echo "Cleaning previous runs from localhost"
rm -rf $GATHER_REPORTS_DIR
mkdir $GATHER_REPORTS_DIR
rm -rf $GATLING_REPORT_DIR

for HOST in "${HOSTS[@]}"
do
  echo "Cleaning previous runs from host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'rm -rf $GATLING_REPORT_DIR'"
done

for HOST in "${HOSTS[@]}"
do
  echo "Copying simulations to host: $HOST"
  scp -r $GATLING_SIMULATIONS_DIR/* $USER_NAME@$HOST:$GATLING_SIMULATIONS_DIR
done

for HOST in "${HOSTS[@]}"
do
  echo "Running simulation on host: $HOST"
  ssh -n -f $USER_NAME@$HOST "sh -c 'nohup $GATLING_RUNNER -nr -s $SIMULATION_NAME > /gatling/run.log 2>&1 &'"
done
