#!/bin/bash
# Name: 	run.sh
# Usage:	./run.sh ENV_CONF_FILE_PATH 
# Example:	./run.sh cfg/maiax86_64.cfg 
# Desc:		Runnig scripts for deploying and testing SES

sript_start_time=$(date +%s)

if [[ -z $1 ]]
then
  echo "ERROR: Argument missing. USAGE example: ./run.sh cfg/maiax86_64.cfg"
  exit 1
else
  source $1
fi

set -x 

# LOGS
LOG_DIR=depl_$(date +%Y_%m_%d_%H_%M)
LOG_PATH=log/${LOG_DIR}
mkdir -p $LOG_PATH

# VMs 
./$VM_PREP_SCRIPT $1

# REPO ISO 
./$TESTING_REPO_SCRIPT $1

# SALT-STACK
if [[ $INSTALL_SALT == YES ]] 
then
  ./$INSTALL_SALT_SCRIPT $1
fi

# SES DEPLOY
./$SES_DEPLOY_SCRIPT $1 > ${LOG_PATH}/TC000_SES_deployment.log 2>&1

########################################################
# TEST SUITE/TESTS

## Preparation 
### Copying helper script to all hodes 
for (( i=1; i <= $VM_NUM; i++ ))
do 
  scp src/node_helper.sh root@${NAME_BASE}${i}:/tmp/
done

for test in $(egrep '^3_tests' $TEST_SUITE)
do
  ./${test} $1 $LOG_PATH
done

########################################################
set +x

REPORT_SUMM=$LOG_PATH/REPORT_SUMMARY
> $REPORT_SUMM

# CHECKING LOGS
echo 
echo '=========================================================================================' >> $REPORT_SUMM
for TC_log in $(find ./${LOG_PATH}/ -name "TC*log")
do 
  tail -n 3 $TC_log|grep -q "Result: OK" && echo 'Result: OK | '$TC_log  >> $REPORT_SUMM || echo 'FAILED     | '$TC_log >> $REPORT_SUMM
done
echo '=========================================================================================' >> $REPORT_SUMM
# calculating script execution duration
sript_end_time=$(date +%s);script_runtime=$(((sript_end_time-sript_start_time)/60))
echo "Runtime in minutes : " $script_runtime >> $REPORT_SUMM
echo '=========================================================================================' >> $REPORT_SUMM

cat $REPORT_SUMM
echo
