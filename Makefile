MODULES = vmmon vmnet
SUBDIRS = $(MODULES:%=%-only)
TARBALLS = $(MODULES:%=%.tar)
MODFILES = $(foreach mod,$(MODULES),$(mod)-only/$(mod).ko)
VM_UNAME = $(shell uname -r)
MODDIR = /lib/modules/$(VM_UNAME)/misc
CURPWD = $(shell pwd)
COMMITCOUNT = $(shell git rev-list --all --count)
COMMITHASH = $(shell git rev-parse --short HEAD)

MODINFO = /sbin/modinfo
DEPMOD = /sbin/depmod

%.tar: FORCE gitcleancheck
	git archive -o $@ --format=tar HEAD $(@:.tar=-only)

.PHONY: FORCE subdirs $(SUBDIRS) clean tarballs

subdirs: retiredcheck $(SUBDIRS)

FORCE:

$(SUBDIRS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

gitcheck:
	@git status >/dev/null 2>&1 \
	     || ( echo "This only works in a git repository."; exit 1 )

gitcleancheck: gitcheck
	@git diff --exit-code HEAD >/dev/null 2>&1 \
	     || echo "Warning: tarballs will reflect current HEAD (no uncommited changes)"

retiredcheck:
	@test -f RETIRED && cat RETIRED || true

install: retiredcheck $(MODFILES)
	@for f in $(MODFILES); do \
	    mver=$$($(MODINFO) -F vermagic $$f);\
	    mver=$${mver%% *};\
	    test "$${mver}" = "$(VM_UNAME)" \
	        || ( echo "Version mismatch: module $$f $${mver}, kernel $(VM_UNAME)" ; exit 1 );\
	done
	install -D -t $(DESTDIR)$(MODDIR) $(MODFILES)
	strip --strip-debug $(MODULES:%=$(DESTDIR)$(MODDIR)/%.ko)
	if test -z "$(DESTDIR)"; then $(DEPMOD) -a $(VM_UNAME); fi

clean: $(SUBDIRS)
	rm -f *.o

akmod/build:
	sudo dnf groupinstall -y "Development Tools"
	sudo dnf install -y rpmdevtools kmodtool
	mkdir -p $(CURPWD)/.tmp/vmware-host-modules-1.0.${COMMITCOUNT}/vmware-host-modules
	cp -r LICENSE Makefile vmmon-only vmnet-only $(CURPWD)/.tmp/vmware-host-modules-1.0.${COMMITCOUNT}/vmware-host-modules
	cd .tmp && tar -czvf vmware-host-modules-1.0.${COMMITCOUNT}.tar.gz vmware-host-modules-1.0.${COMMITCOUNT} && cd -
	mkdir -p $(CURPWD)/.tmp/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	cp $(CURPWD)/.tmp/vmware-host-modules-1.0.${COMMITCOUNT}.tar.gz $(CURPWD)/.tmp/rpmbuild/SOURCES/
	echo 'vmware-host-modules' | tee $(CURPWD)/.tmp/rpmbuild/SOURCES/vmware-host-modules.conf
	cp fedora/*.spec $(CURPWD)/.tmp/rpmbuild/SPECS/
	sed -i "s/MAKEFILE_PKGVER/$(COMMITCOUNT)/g" $(CURPWD)/.tmp/rpmbuild/SPECS/*
	sed -i "s/MAKEFILE_COMMITHASH/$(COMMITHASH)/g" $(CURPWD)/.tmp/rpmbuild/SPECS/*
	rpmbuild -ba --define "_topdir $(CURPWD)/.tmp/rpmbuild" $(CURPWD)/.tmp/rpmbuild/SPECS/vmware-host-modules.spec
	rpmbuild -ba --define "_topdir $(CURPWD)/.tmp/rpmbuild" $(CURPWD)/.tmp/rpmbuild/SPECS/vmware-host-modules-kmod.spec

akmod/install: akmod/build
	sudo dnf install $(CURPWD)/.tmp/rpmbuild/RPMS/*/*.rpm

akmod/akmod-install: retiredcheck $(MODFILES)
	@for f in $(MODFILES); do \
	    mver=$$($(MODINFO) -F vermagic $$f);\
	    mver=$${mver%% *};\
	    test "$${mver}" = "$(VM_UNAME)" \
	        || ( echo "Version mismatch: module $$f $${mver}, kernel $(VM_UNAME)" ; exit 1 );\
	done
	mkdir -p $(KMOD_INSTALL_DIR)
	install -D -m 755 $(MODFILES) $(KMOD_INSTALL_DIR)
	strip --strip-debug $(MODULES:%=$(KMOD_INSTALL_DIR)/%.ko)
	if test -z "$(KMOD_INSTALL_DIR)"; then $(DEPMOD) -a $(VM_UNAME); fi

akmod/clean:
	sudo dnf remove vmware-host-modules
	rm -rf .tmp

akmod: akmod/install

tarballs: $(TARBALLS)

