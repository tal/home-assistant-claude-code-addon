#!/bin/bash

# Wait for initial startup
sleep 5

# Run forever, checking for credentials
while true; do
    /usr/local/bin/credentials-manager save > /dev/null 2>&1
    sleep 30
done