#!/bin/bash

##### Check root #####
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi

##### Creating 4 loop devices #####
echo "-------------------------------------------"
echo "Creating 4 loop devices"
for i in {0..3}; do
	echo "Creating file number $i ..."
	dd if=/dev/zero of=loop$i bs=1MB count=200 #creating files
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
mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/loop2 /dev/loop3
echo "Creating RAID1 ..."
mdadm --create --verbose /dev/md1 --level=1 --raid-devices=2 /dev/loop0 /dev/loop1
echo "You can examine the created raid devices in detail using \"mdadm --detail /dev/md_number\" "

###### Creating VG #####
echo "-----------------------------------------------"
echo "Creating Volume group on top of RAID0 RAID1 ..."
vgcreate FIT_vg /dev/md0 /dev/md1

##### Creating LVM #####
echo "-----------------------------------------------"
echo "Creating LVM Logical volume in Volume group FIT_vg ..."
lvcreate FIT_vg -n FIT_lv1 -L100M #Creating 2 logical volumes of size 100MB
lvcreate FIT_vg -n FIT_lv2 -L100M

##### Creating EXT4 FS #####
echo "-----------------------------------------------"
echo "Creating EXT4 FS on FIT_lv1 logical volume ..."
mkfs.ext4 /dev/FIT_vg/FIT_lv1

##### Creating XFS #####
echo "------------------------------------------------"
echo "Creating XFS on FIT_lv2 logical volume ..."
mkfs.xfs /dev/FIT_vg/FIT_lv2

##### Mounting FIT_lv1 to /mnt/test1 and FIT_lv2 to /mnt/test2 #####
echo "------------------------------------------------"
echo "Creating directories test1 test2 in /mnt..."
mkdir -p -v /mnt/test1 /mnt/test2
echo "Mounting FIT_lv1 to /mnt/test1 ..."
mount /dev/FIT_vg/FIT_lv1 /mnt/test1
echo "Mounting FIT_lv2 to /mnt/test2 ..."
mount /dev/FIT_vg/FIT_lv2 /mnt/test2


##### Resizing filesystem on FIT_1v1 to claim all available space in VG #####
echo "-------------------------------------------------"
echo "Resizing fs on FIT_1v1 ..."
resize2fs -M /mnt/test1
echo "Verifying ..."
df -h

##### Creating 300MB file /mnt/test1/big_file and feeding it with data #####
echo "--------------------------------------------------"
echo "Creating 300MB file in /mnt/test1/big_file and feeding with data ..."
dd if=/dev/urandom of=/mnt/test1/big_file bs=1MB count=300

##### Creating a checksum of the file /mnt/test1/big_file using tool 'sha512sum' #####
echo "Creating checksum ..."
sha512sum --check /mnt/test1/big_file

##### Emulating faulty disk replacement #####
echo "---------------------------------------------------"
echo "Creating 5th loop device representing new disk (200 MB) ..."
