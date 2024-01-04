#!/bin/bash
cd
sed -i '$a\dtoverlay=dwc2' /boot/config.txt
echo
sed -i 's/$/ modules-load=dwc2/' /boot/cmdline.txt
echo
sed -i '$a\libcomposite' /etc/modules
echo
sudo wget -c "https://github.com/PIBSAS/pizero2wEth/blob/main/usb-gadget.sh" -P "/usr/local/sbin/"
echo
sudo chmod +x /usr/local/sbin/usb-gadget.sh
echo
sudo wget -c "https://github.com/PIBSAS/pizero2wEth/blob/main/usbgadget.service" -P "/lib/systemd/system/"
echo
sudo systemctl enable usbgadget.service
echo
echo "Network Manager Settings"
echo
sudo nmcli con add type bridge ifname br0
echo
sudo nmcli con add type bridge-slave ifname usb0 master br0
echo
sudo nmcli con add type bridge-slave ifname usb1 master br0
echo
sudo nmcli connection modify bridge-br0 ipv4.method manual ipv4.addresses 10.55.0.1/24
echo
echo "dnsMasq"
echo
sudo apt install -y dnsmasq
echo
sudo wget -c "https://github.com/PIBSAS/pizero2wEth/blob/main/br0" -P "/etc/dnsmasq.d/"
echo
