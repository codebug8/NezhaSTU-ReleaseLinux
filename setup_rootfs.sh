#!/usr/bin/env bash

set -eou pipefail

keyring_option="--keyring /usr/share/keyrings/debian-ports-archive-keyring.gpg"
if [ $# -eq 1 ]; then
	if [ $1 = "--no-check-gpg" ]; then
		keyring_option="--no-check-gpg"
	fi
fi

if sudo debootstrap --arch=riscv64  --components main,contrib,non-free --include=pciutils,autoconf,automake,autotools-dev,curl,python3,libmpc-dev,libmpfr-dev,libgmp-dev,gawk,build-essential,bison,flex,libtool,patchutils,bc,zlib1g-dev,wpasupplicant,htop,net-tools,wireless-tools,openssh-client,openssh-server,sudo,e2fsprogs,git,man-db,lshw,dbus,wireless-regdb,libsensors5,libssl-dev,python3-distutils,python3-dev,fakeroot,dkms,libblkid-dev,uuid-dev,libudev-dev,libaio-dev,libattr1-dev,libelf-dev,python3-setuptools --foreign hirsute rootfs http://ports.ubuntu.com/ubuntu-ports

then
	echo "Created rootfs"
else
	echo "Failed to create rootfs using debootstrap."
	echo "If the error is that the keyring is missing or out-of-date,"
	echo "this command can be re-run with the --no-check-gpg option."
fi

pushd linux-build
sudo make modules_install ARCH=riscv INSTALL_MOD_PATH=../rootfs KERNELRELEASE=5.17.0-rc2-379425-g06b026a8b714
popd


sudo rm rootfs/lib/modules/5.17.0-rc2-379425-g06b026a8b714/build
sudo rm rootfs/lib/modules/5.17.0-rc2-379425-g06b026a8b714/source
sudo depmod -a -b rootfs 5.17.0-rc2-379425-g06b026a8b714


#echo "Set root user password to: 100ask"
sudo sed  's%^root:[^:]*:%root:$6$QkgMDDAP$qSmQAFBZTsFXCDFxK.Rwsy4Ik.J\/bSzsI6fW.fSX5kzEW4YRWTgJpzo8c9YTMm3XTkjsNgcudaUN7ha624PHh0:%' rootfs/etc/shadow

sudo cp fstab rootfs/etc/

sudo rm -f /tmp/wlan0_contents
cat > /tmp/wlan0_contents << EOF
allow-hotplug wlan0
iface wlan0 inet dhcp
	wpa-ssid 100ask
	wpa-psk 100ask
EOF
sudo cp /tmp/wlan0_contents rootfs/etc/network/interfaces.d/
sudo rm /tmp/wlan0_contents

echo "Set host name to 'NezhaSTU'"
sudo sh -c 'echo nezhastu > rootfs/etc/hostname'
sudo sh -c 'echo "@reboot for i in 1 2 3 4 5; do /usr/sbin/ntpdate 0.europe.pool.ntp.org && break || sleep 15; done" >> rootfs/var/spool/cron/crontabs/root'
sudo chmod 600 rootfs/var/spool/cron/crontabs/root

