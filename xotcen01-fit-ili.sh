#!/bin/bash

echo "Creating 4 loop devices"
for i in {0..3}; do
	echo "Creating file number $i ..."
	dd if=/dev/zero of=loop$i bs=200M count=1 #creating files
done

#cp loop0 loop1 loop2 loop3 IDK

for i in {0..3}; do
	echo "Creating loop device $i ..."
	losetup -fP loop$i  #creating loop device 
done

echo "Success"
echo "To print the loop device generated using the above command use \"losetup-a\"" 
echo "----------------------------------------------"
###### Creating RAID0 and RAID1 ######
echo "Creating RAID0 ..."
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/loop2 /dev/loop3
echo "Creating RAID1 ..."
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/loop0 /dev/loop1
echo "Success"
echo "You can examine the created raid devices in detail using \"mdadm --detail /dev/md_number\" "

echo "-----------------------------------------------"
echo "Creating Volume group on top of RAID0 RAID1 ..."
vgcreate FIT_vg /dev/md0 /dev/md1

echo "-----------------------------------------------"
echo "Creating LVM Logical volume in Volume group FIT_vg ..."
lvcreate FIT_vg -n FIT_1v1 -L100M
lvcreate FIT_vg -n FIT_1v2 -L100M
