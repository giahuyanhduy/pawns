#!/bin/bash
# Stop and remove all existing Pawns.app containers
docker stop $(docker ps -q --filter ancestor=iproyal/pawns-cli:latest) 2>/dev/null || true
docker rm $(docker ps -a -q --filter ancestor=iproyal/pawns-cli:latest) 2>/dev/null || true

# Extract the number (4 or 5 digits) before "*****:localhost:22 *****" from /opt/autorun
DEVICE_NUM=$(grep -oP '\d{4,5}(?=\s*\*\*\*\*\*:localhost:22\s*\*\*\*\*\*)' /opt/autorun | head -n 1)

# Check if DEVICE_NUM was found, otherwise set a default
if [ -z "$DEVICE_NUM" ]; then
    DEVICE_NUM="unknown"
fi

# Pull and run Pawns.app container with extracted number as device-name and device-id
docker pull iproyal/pawns-cli:latest
docker run -d --restart=unless-stopped iproyal/pawns-cli:latest -email=giahuyanhduy@gmail.com -password=Anhduy3112 -device-name=$DEVICE_NUM -device-id=$DEVICE_NUM -accept-tos
