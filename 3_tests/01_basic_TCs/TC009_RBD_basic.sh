#!/bin/bash
echo "================================================================"

set -ex 

source src/helper.sh
source_cfg $@
echo $NAME_BASE
LOG=$(setup_log_path $@)
echo "Log path: " $LOG

POOL_NAME=rbd_test

# Create pool
ssh root@$MASTER ceph osd pool delete $POOL_NAME $POOL_NAME --yes-i-really-really-mean-it > $LOG 2>&1
ssh root@$MASTER ceph osd pool create $POOL_NAME 16 16 replicated > $LOG 2>&1

# Copy client.admin keyring to Client Node 
scp root@ses5node1:/etc/ceph/ceph.client.admin.keyring /tmp/ceph.client.admin.keyring
scp /tmp/ceph.client.admin.keyring root@ses5node5:/etc/ceph/

# Run client test 
ssh root@$CLIENT_NODE 'bash -s' < 3_tests/client/rbd_client_test.sh $POOL_NAME > $LOG 2>&1

echo "Result: OK"

set +ex 
