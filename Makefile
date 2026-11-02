# Per-user install (default):     make install
# For every user on the machine:  sudo make install PREFIX=/usr/local QUADLETDIR=/etc/containers/systemd/users
NAME       := citrix-workspace
PREFIX     ?= $(HOME)/.local
QUADLETDIR ?= $(HOME)/.config/containers/systemd
BINDIR     := $(PREFIX)/bin
SHAREDIR   := $(PREFIX)/share

FILES := $(BINDIR)/$(NAME) \
         $(SHAREDIR)/$(NAME)/Containerfile \
         $(SHAREDIR)/$(NAME)/entrypoint.sh \
         $(SHAREDIR)/applications/$(NAME).desktop \
         $(SHAREDIR)/icons/hicolor/scalable/apps/$(NAME).svg \
         $(QUADLETDIR)/$(NAME).container

.PHONY: install uninstall check

install:
	install -Dm755 bin/$(NAME) $(DESTDIR)$(BINDIR)/$(NAME)
	install -Dm644 -t $(DESTDIR)$(SHAREDIR)/$(NAME) share/$(NAME)/Containerfile share/$(NAME)/entrypoint.sh
	install -Dm644 share/icons/hicolor/scalable/apps/$(NAME).svg $(DESTDIR)$(SHAREDIR)/icons/hicolor/scalable/apps/$(NAME).svg
	install -d $(DESTDIR)$(SHAREDIR)/applications $(DESTDIR)$(QUADLETDIR)
	sed 's|@BINDIR@|$(BINDIR)|g' share/applications/$(NAME).desktop.in > $(DESTDIR)$(SHAREDIR)/applications/$(NAME).desktop
	sed 's|@BINDIR@|$(BINDIR)|g' systemd/$(NAME).container.in > $(DESTDIR)$(QUADLETDIR)/$(NAME).container
	-systemctl --user daemon-reload 2>/dev/null

# Removes the program and, with it, everything Citrix stored: image, settings, cache and downloads.
uninstall:
	-$(BINDIR)/$(NAME) purge
	rm -f $(addprefix $(DESTDIR),$(FILES))
	-rmdir $(DESTDIR)$(SHAREDIR)/$(NAME) 2>/dev/null
	-systemctl --user daemon-reload 2>/dev/null

check:
	shellcheck bin/$(NAME) share/$(NAME)/entrypoint.sh && echo "shellcheck: OK"
	@if [ -x /usr/libexec/podman/quadlet ]; then \
	  d=$$(mktemp -d) && sed 's|@BINDIR@|$(BINDIR)|g' systemd/$(NAME).container.in > $$d/$(NAME).container \
	  && QUADLET_UNIT_DIRS=$$d /usr/libexec/podman/quadlet -dryrun -user >/dev/null; s=$$?; rm -rf $$d; \
	  [ $$s -eq 0 ] && echo "quadlet: OK" || exit $$s; \
	fi
