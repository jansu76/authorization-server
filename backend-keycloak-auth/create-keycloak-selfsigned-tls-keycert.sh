#!/bin/bash
openssl req -newkey rsa:2048 -nodes -keyout server.key.pem -x509 -days 3650 -out server.crt.pem
chmod 775 server.key.pem
