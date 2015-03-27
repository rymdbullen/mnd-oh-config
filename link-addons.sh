#!/bin/bash
AVAIL_ADDONS_DIR="/opt/openhab/addons-available/"

for f in $(cat /opt/openhab/configurations/addons.cfg); do ln -s /opt/openhab/addons-available/$f /opt/openhab/addons/$f; done
