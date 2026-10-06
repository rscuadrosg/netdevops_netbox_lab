#!/usr/bin/env bash
# Start NetBox with netbox-docker. It is cloned OUTSIDE the repo (in $HOME)
# so it never gets committed to the project.
set -euo pipefail

NETBOX_DIR="${NETBOX_DIR:-$HOME/netbox-docker}"

if [ ! -d "$NETBOX_DIR" ]; then
  git clone -b release https://github.com/netbox-community/netbox-docker.git "$NETBOX_DIR"
fi

cd "$NETBOX_DIR"

# The Codespaces port-forwarding proxy rewrites the Origin header to
# https://localhost:8000, which Django rejects as a CSRF origin unless trusted.
cat > docker-compose.override.yml <<EOF
services:
  netbox:
    ports:
      - "8000:8080"
    environment:
      CSRF_TRUSTED_ORIGINS: "http://localhost:8000 https://localhost:8000"
EOF

#run the docker compose to start netbox
docker compose pull
docker compose up -d

#print some instructions to the user
echo
echo "NetBox is starting. First boot takes a few minutes (migrations)."
echo "Follow logs:   cd $NETBOX_DIR && docker compose logs -f netbox"
echo "Create admin:  cd $NETBOX_DIR && docker compose exec netbox /opt/netbox/netbox/manage.py createsuperuser"
echo "Open:          Codespace Ports tab -> port 8000"
