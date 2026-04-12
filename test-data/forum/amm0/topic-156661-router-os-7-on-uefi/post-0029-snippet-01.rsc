# Source: https://forum.mikrotik.com/t/router-os-7-on-uefi/156661/29
# Topic: Router OS 7 on UEFI
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ROSVER=7.16rc4
wget --no-check-certificate https://download.mikrotik.com/routeros/$ROSVER/chr-$ROSVER.img.zip -O /tmp/chr-$ROSVER.img.zip
unzip -p /tmp/chr-$ROSVER.img.zip > /tmp/chr-$ROSVER.img
rm -rf  chr-$ROSVER.qcow2
qemu-img convert -f raw -O qcow2 /tmp/chr-$ROSVER.img chr-$ROSVER.qcow2
rm -rf /tmp/chr-$ROSVER.im*

modprobe nbd
qemu-nbd -c /dev/nbd0 chr-$ROSVER.qcow2

rm -rf /tmp/tmp*

mkdir /tmp/tmpmount/
mkdir diskfiles

mkdir /tmp/tmpefipart/
mount /dev/nbd0p1 /tmp/tmpmount/
rsync -a /tmp/tmpmount/ /tmp/tmpefipart/
mkdir diskfiles/part1
rsync -a /tmp/tmpmount/ ./diskfiles/part1/
umount /dev/nbd0p1

mkfs -t fat /dev/nbd0p1
mount /dev/nbd0p1 /tmp/tmpmount/
rsync -a /tmp/tmpefipart/ /tmp/tmpmount/
umount /dev/nbd0p1

mount /dev/nbd0p2 /tmp/tmpmount/
mkdir diskfiles/part2
rsync -a /tmp/tmpmount/ ./diskfiles/part2/
umount /dev/nbd0p2

rm -rf /tmp/tmp*

# ALL GDISK MODS DISABLE
# @kriszos approach
# (
# echo 2 # use GPT
# ...
# echo y # confirm
# ) | gdisk /dev/nbd0
# @jaclaz
# (
# echo 2 # use GPT
# ...
# echo y # confirm
# ) | gdisk /dev/nbd0

qemu-nbd -d /dev/nbd0

echo "created file chr.qcow2, now back to raw but uncompressed..."
qemu-img convert -f qcow2 -O raw chr-$ROSVER.qcow2 chr-$ROSVER.uefi-fat.raw
