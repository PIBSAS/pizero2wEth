#!/bin/bash
sed -i '$a\dtoverlay=dwc2' /boot/config.txt
sed -i 's/$/ modules-load=dwc2/' /boot/cmdline.txt
sed -i '$a\libcomposite' /etc/modules
wget -c "https://github.com/PIBSAS/pizero2wEth/blob/main/usb-gadget.sh" -P "/usr/local/sbin/"
sudo chmod +x /usr/local/sbin/usb-gadget.sh
