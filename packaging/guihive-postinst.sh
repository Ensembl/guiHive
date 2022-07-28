#!/bin/sh
firewall-cmd --zone=public --add-port=8080/tcp --permanent
firewall-cmd --reload
