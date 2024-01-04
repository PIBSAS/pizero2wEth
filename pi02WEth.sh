#!/bin/bash
cd
echo "Update Kernel"
echo
echo "yes" | sudo rpi-update
echo
echo "Move to /boot to make changes"
echo
cd /boot
sudo sed -i 's/dtoverlay=dwc2//g' config.txt
sudo sed -i '$a\dtoverlay=dwc2' config.txt
echo
sudo sed -i 's/ modules-load=dwc2//g' cmdline.txt
sudo sed -i 's/$/ modules-load=dwc2/' cmdline.txt
echo
cd
echo "Move to /etc to make changes"
echo
cd /etc
sudo sed -i 's/libcomposite//g' modules
sudo sed -i '$a\libcomposite' modules
echo
cd
echo
echo "Clean file made before so the new is the correct"
echo
sudo rm /usr/local/sbin/usb-gadget.sh
#sudo wget -c "https://raw.githubusercontent.com/PIBSAS/pizero2wEth/main/usb-gadget.sh" -P "/usr/local/sbin/"
echo '#!/bin/bash

cd /sys/kernel/config/usb_gadget/
mkdir -p display-pi
cd display-pi
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0103 > bcdDevice # v1.0.3
echo 0x320 > bcdUSB # USB2
echo 2 > bDeviceClass
mkdir -p strings/0x409
echo "fedcba9876543213" > strings/0x409/serialnumber
echo "Ben Hardill" > strings/0x409/manufacturer
echo "Display-Pi USB Device" > strings/0x409/product
mkdir -p configs/c.1/strings/0x409
echo "CDC" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower
echo 0x80 > configs/c.1/bmAttributes

#ECM
mkdir -p functions/ecm.usb0
HOST="00:dc:c8:f7:75:15" # "HostPC"
SELF="00:dd:dc:eb:6d:a1" # "BadUSB"
echo $HOST > functions/ecm.usb0/host_addr
echo $SELF > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1/

#RNDIS
mkdir -p configs/c.2
echo 0x80 > configs/c.2/bmAttributes
echo 0x250 > configs/c.2/MaxPower
mkdir -p configs/c.2/strings/0x409
echo "RNDIS" > configs/c.2/strings/0x409/configuration

echo "1" > os_desc/use
echo "0xcd" > os_desc/b_vendor_code
echo "MSFT100" > os_desc/qw_sign

mkdir -p functions/rndis.usb0
HOST_R="00:dc:c8:f7:75:16"
SELF_R="00:dd:dc:eb:6d:a2"
echo $HOST_R > functions/rndis.usb0/dev_addr
echo $SELF_R > functions/rndis.usb0/host_addr
echo "RNDIS" > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
echo "5162001" > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id

ln -s functions/rndis.usb0 configs/c.2
ln -s configs/c.2 os_desc

udevadm settle -t 5 || :
ls /sys/class/udc > UDC

sleep 5

nmcli connection up bridge-br0
nmcli connection up bridge-slave-usb0
nmcli connection up bridge-slave-usb1
sleep 5
service dnsmasq restart' | sudo tee /usr/local/sbin/usb-gadget.sh > /dev/null
echo
echo "Make executable"
echo
sudo chmod +x /usr/local/sbin/usb-gadget.sh
echo
cd
echo "Clean file made before so the new is the correct"
echo
sudo rm /lib/systemd/system/usbgadget.service
echo "[Unit]
Description=My USB gadget
After=network-online.target
Wants=network-online.target
#After=systemd-modules-load.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/usb-gadget.sh

[Install]
WantedBy=sysinit.target" | sudo tee /lib/systemd/system/usbgadget.service > /dev/null
echo
#sudo wget -c "https://github.com/PIBSAS/pizero2wEth/blob/main/usbgadget.service" -P "/lib/systemd/system/"
echo
echo "Enable USB Gadget Service"
echo
sudo systemctl enable usbgadget.service
echo
echo "Network Manager Settings"
echo
echo "Delete the bridge connection and slave connections made previously to  make the correct ones"
echo
sudo nmcli connection delete bridge-br0
sudo nmcli connection delete bridge-slave-usb0
sudo nmcli connection delete bridge-slave-usb1
#sudo nmcli connection delete br0
echo
echo "Make the bridge and slave connections"
echo
sudo nmcli con add type bridge ifname br0
sudo nmcli con add type bridge-slave ifname usb0 master br0
sudo nmcli con add type bridge-slave ifname usb1 master br0
echo "Config IP addreses to use 10.55.0.1/24 for our Raspberry PI USB Gadget"
sudo nmcli connection modify bridge-br0 ipv4.method manual ipv4.addresses 10.55.0.1/24
echo
echo "Install dnsMasq if it is not already"
echo
sudo apt install -y dnsmasq
echo
echo "Clean file made before so the new is the correct"
echo
sudo rm /etc/dnsmasq.d/br0
#sudo wget -c "https://raw.githubusercontent.com/PIBSAS/pizero2wEth/main/br0" -P "/etc/dnsmasq.d/"
echo "dhcp-authoritative
dhcp-rapid-commit
no-ping
interface=br0
dhcp-range=10.55.0.2,10.55.0.6,255.255.255.248,1h
dhcp-option=3
leasefile-ro" | sudo tee /etc/dnsmasq.d/br0 > /dev/null
echo
echo "Finish Reboot system please"
sudo reboot
