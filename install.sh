#!/bin/bash

function check_root() {
	if [[ $EUID -ne 0 ]]; then
		echo "$1 you must be run as root"
		exit 1
	fi
}

function install_package() {

	git clone https://github.com/torproject/tor.git
	cd tor
	sh autogen.sh && ./configure && make && make install
	cd ..
	go get git.torproject.org/pluggable-transports/obfs4.git/obfs4proxy
	git clone https://github.com/rofl0r/proxychains-ng.git
	cd proxychains-ng
	./configure --prefix=/usr --sysconfdir=/etc # configure and install
	make
	make install && make install-config # installs /etc/proxychains.conf
	cd ..
}

function check_net() {
	if ! ping google.com -c 1 1>/dev/null 2>&1; then
		echo "you must connect to internet"
		exit 1
	fi
}

function config_ddtorrc() {
	if cat ddtorrc | grep "obfs4" >/dev/null; then
		if [ -f "/etc/tor/torrc" ]; then
			echo "Backup the old torrc to '/etc/tor/torrc.ddtor-backup'..."
			cp /etc/tor/torrc /etc/tor/torrc.ddtor-backup
			rm /etc/tor/torrc
			touch /etc/tor/torrc
		fi
		echo "Log notice syslog" | tee -a /etc/tor/torrc >/dev/null
		echo "DataDirectory /var/lib/tor" | tee -a /etc/tor/torrc >/dev/null
		echo "UseBridges 1" | tee -a /etc/tor/torrc >/dev/null
		echo "ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy" | tee -a /etc/tor/torrc >/dev/null
		sed s/" obfs4"/"bridge obfs4"/g ddtorrc | tee -a /etc/tor/torrc >/dev/null
	else
		echo "ddtroc is empty please see README file"
		exit 1
	fi
}

function install_ddtor() {
	cp ddtor.sh /bin/ && mv /bin/ddtor.sh /bin/ddtor
	chmod 755 /bin/ddtor
}

check_root "for install"
check_net
install_package
config_ddtorrc
install_ddtor
