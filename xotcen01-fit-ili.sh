#!/bin/bash

################################## BEGIN ###################################
echo "
----------------------------------------------------------------------------
        			  BEGIN
----------------------------------------------------------------------------
"

##### Check root #####
if [[ $EUID -ne 0 ]]; then
	echo "This script must be run as root"
	exit 1
fi


##### Creating 4 loop devices #####
echo "
-----------------------------------------------------
1. CREATING 4 LOOP DEVICES EACH OF SIZE 200MB
-----------------------------------------------------
"

for i in {0..3}; do
	echo "Creating file number $i ..."
	dd if=/dev/zero of=disk$i bs=200MB count=1 #creating files
done

for i in {0..3}; do
	echo "Creating loop device $i ..."
	losetup loop$i disk$i  #creating loop device 
done
 

###### Creating RAID0 and RAID1 ######
echo "
----------------------------------------------
2. CREATING SOFTWARE RAID0 AND RAID1
----------------------------------------------
"

echo "
Creating RAID0 ..."
mdadm --create /dev/md/RAID0 --level=stripe --raid-devices=2 /dev/loop2 /dev/loop3 -R #RAID0

echo "
Creating RAID1 ..."
mdadm --create /dev/md/RAID1 --level=mirror --raid-devices=2 /dev/loop0 /dev/loop1 -R #RAID1

echo "
Showing changes ..."
#mdadm --detail /dev/md0 /dev/md1
cat /proc/mdstat


###### Creating VG #####
echo "
-----------------------------------------------
3. CREATING VOLUME GROUP
-----------------------------------------------
"

echo "
Creating Volume group on top of RAID0 RAID1 ..."
vgcreate FIT_vg /dev/md/RAID0 /dev/md/RAID1

echo "
Displaying volume group ..."
vgdisplay FIT_vg


##### Creating LVM #####
echo "
-----------------------------------------------
4. CREATING LOGICAL VOLUME GROUPS
-----------------------------------------------
"

echo "
Creating LVM Logical volume in Volume group FIT_vg ..."
lvcreate FIT_vg -n FIT_lv1 -L100MB #Creating 2 logical volumes of size 100MB
lvcreate FIT_vg -n FIT_lv2 -L100MB

echo "
Displaying LVM ..."
lvdisplay FIT_vg


##### Creating EXT4 FS #####
echo "
-----------------------------------------------
5. CREATING EXT4 FILESYSTEM
-----------------------------------------------
"

echo "
Creating EXT4 FS on FIT_lv1 logical volume ..."
mkfs.ext4 /dev/FIT_vg/FIT_lv1


##### Creating XFS #####
echo "
---------------------------------------------
6. CREATING XFS
---------------------------------------------
"

echo "
Creating XFS on FIT_lv2 logical volume ..."
mkfs.xfs /dev/FIT_vg/FIT_lv2


##### Mounting FIT_lv1 to /mnt/test1 and FIT_lv2 to /mnt/test2 #####
echo "
---------------------------------------------------------------
7. MOUNTING FIT_lv1 TO /mmnt/test1 AND FIT_lv2 TO /mnt/test2
---------------------------------------------------------------
"

echo "
Creating directories test1 test2 in /mnt..."
mkdir -p /mnt/test1 /mnt/test2

echo "
Mounting FIT_lv1 to /mnt/test1 ..."
mount /dev/FIT_vg/FIT_lv1 /mnt/test1

echo "
Mounting FIT_lv2 to /mnt/test2 ..."
mount /dev/FIT_vg/FIT_lv2 /mnt/test2


##### Resizing filesystem on FIT_1v1 to claim all available space in VG #####
echo "
-------------------------------------------------------------------------------
8. RESIZING FILESYSTEM ON FIT_lv1 TO CLAIM ALL AVAILABLE SPACE IN VOLUME GROUP
-------------------------------------------------------------------------------
"

echo "
Printing informations ..."
df -h

echo "
Resizing filesystem on FIT_1v1 ..."
umount /dev/FIT_vg/FIT_lv1

lvextend -l +100%FREE /dev/FIT_vg/FIT_lv1
e2fsck -f /dev/FIT_vg/FIT_lv1 #checking 
resize2fs /dev/FIT_vg/FIT_lv1

mount /dev/FIT_vg/FIT_lv1 /mnt/test1

echo "
Verifying ..."
df -h


##### Creating 300MB file /mnt/test1/big_file and feeding it with data #####
echo "
-----------------------------------------------------------------------------
9. CREATING 300MB FILE IN /mnt/test1/big_file AND FEEDING IT WITH DATA
-----------------------------------------------------------------------------
"
dd if=/dev/urandom of=/mnt/test1/big_file bs=1MB count=300

echo "
Printing informations ..."
df -h

echo "
Creating checksum ..."
sha512sum  /mnt/test1/big_file


##### Emulating faulty disk replacement #####
echo "
------------------------------------------------------
10. EMULATING FAULTY DISK REPLACEMENT
------------------------------------------------------
"

echo "
Creating 5th loop device representing new disk (200 MB) ..."
dd if=/dev/zero of=disk_replace bs=200MB count=1
losetup loop4 disk_replace

echo "
Setting faulty disk ..."
mdadm --manage /dev/md/RAID1 --fail /dev/loop0

echo "
Printing informations ..."
cat /proc/mdstat

echo "
Removing faulty disk ..." 
mdadm --manage /dev/md/RAID1 --remove /dev/loop0

echo "
Printing informations ..."
cat /proc/mdstat

echo "
Adding new disk ..."
mdadm --manage /dev/md/RAID1 --add /dev/loop4

echo "
Verifying replacement ..."
cat /proc/mdstat

echo "
---------------------------------------------------
                       END
---------------------------------------------------
"
############################## END ################################
