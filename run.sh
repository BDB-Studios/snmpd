#!/bin/bash

# This is the development file

docker run --name snmpd \
	-v /proc:/host_proc \
	-p 161:161/udp \
	snmpd
