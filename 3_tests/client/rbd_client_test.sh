#!/bin/bash
# Requirements:
# 	- input argument is pool name from pool already created 
# 	- client.admin keyring is copied from admin node to client node 

set -ex

RBD_POOL=$1

function rbd_unmap_all {
        MAPPED_IMGs=$(rbd showmapped|grep "/dev/rbd"|awk '{print $5}')
        for img in $MAPPED_IMGs
        do
          rbd unmap $img
        done
}

rpm -qa|grep librbd1 || zypper in -y librbd1

# creating new disk
NEW_DISK=rbd_test_disk_001
rados -n client.admin --keyring=/etc/ceph/ceph.client.admin.keyring -p $RBD_POOL ls
rbd create $NEW_DISK --size 2048 --pool $RBD_POOL
rbd -p $RBD_POOL ls

MAPPED_DEV=$(rbd map $NEW_DISK --pool $RBD_POOL --id admin)
rbd showmapped
DEV_NAME=${MAPPED_DEV##*/}
lsblk|grep ${DEV_NAME}p1 || ( sgdisk --largest-new=1 $MAPPED_DEV; mkfs.xfs ${MAPPED_DEV}p1 -f)
mount|grep mnt && umount /mnt -f
mount ${MAPPED_DEV}p1 /mnt
ls -la /mnt
openssl rand -base64 -out /mnt/rbd_random.txt 1000000
tail /mnt/rbd_random.txt
umount /mnt -f
rbd_unmap_all
rbd showmapped

echo 'Result: OK'

set +ex

