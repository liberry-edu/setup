#!/bin/bash

#all the html content should be in the /var/www/html directory

sudo apt-get -y install hostapd dnsmasq nginx
#hostapd will allow us to recieve connections on wlan0, as if it were a wireless router
#dnsmasq will allow the pi to provide DNS and DHCP services which is the bare minimum we need to get clients to ¨work¨ on the internet
#nginx is the web server to serve the content


cat >hostapd.conf <<EOL
interface=wlan0
ssid=Liberry
hw_mode=g
channel=6
auth_algs=1
wmm_enabled=0
EOL

sudo mv hostapd.conf /etc/hostapd/hostapd.conf

#This will setup the DHCP server, resolve all DNS lookups to 192.168.10.1
cat >dnsmasq.conf <<EOL
address=/#/192.168.10.1
dhcp-range=192.168.10.20,192.168.10.255,12h
interface=wlan0
no-resolv
EOL

sudo mv dnsmasq.conf /etc/dnsmasq.conf

cat >interfaces <<EOL
source-directory /etc/network/interfaces.d

auto lo
iface lo inet loopback

iface eth0 inet dhcp

allow-hotplug wlan0
iface wlan0 inet static
	hostapd /etc/hostapd/hostapd.conf
	address 192.168.10.1
	netmask 255.255.255.0
EOL

sudo mv interfaces /etc/network/interfaces

#Generate SSL Certificates
openssl req \
	-new  \
	-newkey rsa:4096 \
	-days 10000 \
	-nodes \
	-x509 \
	-subj "/C=IN/ST=Delhi/L=Delhi/O=Dis/CN=liberry.in" \
	-keyout key.pem \
	-out cert.pem

sudo mv key.pem /etc/ssl/
sudo mv cert.pem /etc/ssl/

cat >nginx.config <<EOL
server {
	listen 80;
	listen 443 default ssl;
	ssl_certificate /etc/ssl/cert.pem;
	ssl_certificate_key /etc/ssl/key.pem;

	root /var/www/html;
	index index.html index.htm index.nginx-debian.html;

	server_name _;
}
EOL

sudo rm /etc/nginx/sites-enabled/*
sudo mv nginx.config /etc/nginx/sites-available/liberry
sudo ln -s /etc/nginx/sites-available/liberry /etc/nginx/sites-enabled/

sudo service nginx reload
sudo service nginx restart

#Enable IP Forwarding
#sudo bash -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'

#NAT RULES so that if someone types any IP he should be redirected to Liberry's homepage
#sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 127.0.0.1:80
#sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to-destination 127.0.0.1:80

#save the iptables rule so that when the pi is rebooted, rules are loaded automatically
#sudo iptables-save
