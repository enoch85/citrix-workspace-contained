#!/bin/sh
# Container entrypoint: Citrix's background services, then the Workspace window.
# The container, and so the systemd service, ends once the window is closed and no session is open.
rm -rf "$HOME/.ICAClient/.tmp"   # lock files left by a crashed run make the next start hang
dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
# Citrix keeps its sign-in in the default keyring, and libsecret would name that "Default keyring".
# Create it first under our own name, but only if there is none: asking again would prompt to unlock it.
[ -s "$HOME/.local/share/keyrings/default" ] || python3 -c '
import gi
gi.require_version("Secret", "1")
from gi.repository import Secret
Secret.Collection.create_sync(None, "Citrix Workspace", "default", Secret.CollectionCreateFlags(0), None)
'
"$ICAROOT/util/ctxcwalogd"
selfservice "$@"
while pgrep -x wfica >/dev/null; do sleep 5; done
