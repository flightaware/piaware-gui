#
# piaware-gui - piaware HDMI graphical output
#
# invoke with wish -f /usr/local/lib/piaware-gui/main.tcl
#

PROGNAME=piaware-gui
PREFIX=/usr
TCLLAUNCHER := $(shell which tcllauncher)

all:
	@echo "'make install' to install $(PROGNAME)"

install:
	install -d $(DESTDIR)$(PREFIX)/bin $(DESTDIR)$(PREFIX)/lib/$(PROGNAME) $(DESTDIR)$(PREFIX)/lib/$(PROGNAME)/icons
	install *.tcl *.gif $(DESTDIR)$(PREFIX)/lib/$(PROGNAME)
	install ./icons/*.png ./icons/*.gif $(DESTDIR)$(PREFIX)/lib/$(PROGNAME)/icons
	install -m 0755 $(PROGNAME) $(DESTDIR)$(PREFIX)/bin
