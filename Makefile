all:
	$(MAKE) -C doc
	$(MAKE) -C po

clean:
	find . -name \*~ | xargs rm -f
	$(MAKE) -C doc clean
	$(MAKE) -C po clean

# Does not attempt to install documentation, as that can be fairly system
# specific.
install: install-utils install-rest

# Anything that goes in the debconf-utils package.
install-utils:
	install -d $(prefix)/usr/bin
	find . -maxdepth 1 -perm +100 -type f -name 'debconf-*' | grep -v debconf-show | grep -v debconf-copydb | \
		xargs -i install {} $(prefix)/usr/bin

# Install all else.
install-rest:
	$(MAKE) -C po install
	install -d $(prefix)/etc \
		$(prefix)/var/cache/debconf \
		$(prefix)/usr/share/debconf \
		$(prefix)/usr/share/pixmaps
	install -m 0644 debconf.conf $(prefix)/etc/
	install -m 0644 debian-logo.xpm $(prefix)/usr/share/pixmaps/
	# This one is the ultimate backup copy.
	grep -v '^#' debconf.conf > $(prefix)/usr/share/debconf/debconf.conf
	# Make module directories.
	find Debconf -type d |grep -v CVS | \
		xargs -i install -d $(prefix)/usr/share/perl5/{}
	# Install modules.
	find Debconf -type f -name '*.pm' |grep -v CVS | \
		xargs -i install -m 0644 {} $(prefix)/usr/share/perl5/{}
	# Special case for back-compatability.
	install -d $(prefix)/usr/share/perl5/Debian/DebConf/Client
	cp Debconf/Client/ConfModule.stub \
		$(prefix)/usr/share/perl5/Debian/DebConf/Client/ConfModule.pm
	# Other libs and helper stuff.
	install -m 0644 confmodule.sh confmodule $(prefix)/usr/share/debconf/
	install frontend $(prefix)/usr/share/debconf/
	install -m 0755 transition_db.pl fix_db.pl $(prefix)/usr/share/debconf/
	# Install essential programs.
	install -d $(prefix)/usr/sbin
	find . -maxdepth 1 -perm +100 -type f -name 'dpkg-*' -or -name debconf-show -or -name debconf-copydb | \
		xargs -i install {} $(prefix)/usr/sbin
	# Now strip all pod documentation from all .pm files and scripts.
	find $(prefix)/usr/share/perl5/ $(prefix)/usr/sbin		\
	     $(prefix)/usr/share/debconf/frontend 			\
	     $(prefix)/usr/share/debconf/*.pl				\
	     -name '*.pm' -or -name 'dpkg-*' | 				\
	     grep -v Client/ConfModule | xargs perl -i.bak -ne ' 	\
	     		print $$_."# This file was preprocessed, do not edit!\n" \
				if m:^#!/usr/bin/perl:; 		\
	     		$$cutting=1 if /^=/; 				\
	     		$$cutting="" if /^=cut/; 			\
			next if /use lib/;				\
			next if $$cutting || /^(=|\s*#)/ || $$_ eq "\n";\
			print $$_					\
		'
	find $(prefix) -name '*.bak' | xargs rm -f

demo:
	PERL5LIB=. ./frontend samples/demo
