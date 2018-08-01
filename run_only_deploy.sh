#!/bin/bash
# Name: 	run.sh
# Usage:	./run.sh ENV_CONF_FILE_PATH 
# Example:	./run.sh cfg/maiax86_64.cfg 
# Desc:		Runnig scripts for deploying and testing SES

if [[ -z $1 ]]
then
  echo "ERROR: ENV_CONF argument missing."
  echo "Example:"
  echo "./run.sh cfg/maiax86_64.cfg"
  exit 1
fi

sript_start_time=$(date +%s)
set -x 

# LOGS
LOG_DIR=depl_$(date +%Y_%m_%d_%H_%M)
LOG_PATH=log/${LOG_DIR}
mkdir -p $LOG_PATH

# VMs 
./1_srv_prep/reset_ses_vms.sh $1

# REPO ISO 
./2_deploy/get_ISO_add_REPO.sh $1

# SALT-STACK
./2_deploy/salt_setup.sh $1

# SES DEPLOY
source $1
sed "s/__NAMEBASE__/${NAME_BASE}/g" cfg/policy.cfg.tmpl > cfg/policy.cfg
scp cfg/policy.cfg root@${NAME_BASE}1:/tmp/
echo "Deployment..."
ssh root@$MASTER 'bash -s' < 2_deploy/ses_deploy_deepsea.sh > ${LOG_PATH}/TC001_ses_deploy_deepsea.log 2>&1
[ $? -eq 0 ] && echo "Deployment OK" || exit 1

sript_end_time=$(date +%s);script_runtime=$(((sript_end_time-sript_start_time)/60))
echo;echo "Runtime in minutes (deployment): " $script_runtime;echo
echo