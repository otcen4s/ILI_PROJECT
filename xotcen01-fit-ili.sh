#!/bin/bash

##### Creating 4 loop devices #####
echo "-------------------------------------------"
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
echo "To print the loop device generated using the above command use \"losetup-a\"" 

###### Creating RAID0 and RAID1 ######
echo "----------------------------------------------"
echo "Creating RAID0 ..."
mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/loop0 /dev/loop1
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/loop2 /dev/loop3
echo "Creating RAID1 ..."
#mdadm --create /dev/md1 --level=1 --raid-devices=2 /dev/loop0 /dev/loop1
echo "You can examine the created raid devices in detail using \"mdadm --detail /dev/md_number\" "

###### Creating VG #####
echo "-----------------------------------------------"
echo "Creating Volume group on top of RAID0 RAID1 ..."
vgcreate FIT_vg /dev/md0 /dev/md1

##### Creating LVM #####
echo "-----------------------------------------------"
echo "Creating LVM Logical volume in Volume group FIT_vg ..."
lvcreate FIT_vg -n FIT_1v1 -L100M #Creating 2 logical volumes of size 100MB
lvcreate FIT_vg -n FIT_1v2 -L100M

##### Creating EXT4 FS #####
echo "-----------------------------------------------"
echo "Creating EXT4 FS on FIT_1v1 logical volume ..."
mkfs.ext4 /dev/FIT_1v1

##### Creating XFS #####
echo "------------------------------------------------"
echo "Creating XFS on FIT_1v2 logical volume ..."
mkfs.xfs /dev/FIT_1v2

##### Mounting FIT_1v1 to /mnt/test1 #####
echo "------------------------------------------------"
echo "Creating directories test1 test2 in /mnt..."
mkdir -v /mnt/test1 /mnt/test2
echo "Mounting FIT_1v1 to /mnt/test1 ..."
mount /dev/FIT_1v1 /mnt/test1
mount /dev/FIT_1v2 /mnt/test2
