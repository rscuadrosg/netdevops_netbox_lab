#!/usr/bin/env bash
# Start NetBox with netbox-docker. It is cloned OUTSIDE the repo (in $HOME)
# so it never gets committed to the project.

set -euo pipefail

NETBOX_DIR="${NETBOX_DIR:-$HOME/netbox-docker}"

if [ ! -d "$NETBOX_DIR" ]; then
  git clone -b release https://github.com/netbox-community/netbox-docker.git "$NETBOX_DIR"
fi

cd "$NETBOX_DIR"

cat > docker-compose.override.yml <<EOF
services:
  netbox:
    ports:
      - "8000:8080"
EOF

docker compose pull
docker compose up -d

echo
echo "NetBox is starting. First boot takes a few minutes (migrations)."
echo "Follow logs:   cd $NETBOX_DIR && docker compose logs -f netbox"
echo "Create admin:  cd $NETBOX_DIR && docker compose exec netbox /opt/netbox/netbox/manage.py createsuperuser"
echo "Open:          Codespace Ports tab -> port 8000"
