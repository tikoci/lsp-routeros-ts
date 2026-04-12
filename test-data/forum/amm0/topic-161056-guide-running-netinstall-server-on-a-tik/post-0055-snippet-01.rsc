# Source: https://forum.mikrotik.com/t/guide-running-netinstall-server-on-a-tik/161056/55
# Topic: GUIDE: Running Netinstall Server on a Tik
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

ARCH ?= arm
PKGS ?= zerotier wifi-qcom-ac
CHANNEL ?= stable
OPTS ?= -b -r
IFACE ?= eth0
#CLIENTIP ?= 172.17.9.101
NET_OPTS ?= $(if $(CLIENTIP),-a $(CLIENTIP),-i $(IFACE))
URLVER ?= https://upgrade.mikrotik.com/routeros/NEWESTa7channel_ver = $(firstword $(shell wget -q -O - $(URLVER).$(1)))
VER ?= $(call channel_ver,$(CHANNEL))
VER_NETINSTALL ?= $(call channel_ver,testing)
PKGS_FILES := $(foreach pkg, $(PKGS), $(pkg)-$(VER)-$(ARCH).npk)
QEMU ?= ./i386
PLATFORM ?= $(shell uname -m)

.PHONY: run all service download clean nothing dump extra-packages stable long-term testing arm arm64 mipsbe mmips smips ppc tile x86
.SUFFIXES:

run: all
	$(eval PKGS_FILES := $(shell for file in $(PKGS_FILES); do if [ -e "./$$file" ]; then echo "$$file"; fi; done))
	@echo starting netinstall... PLATFORM=$(PLATFORM) ARCH=$(ARCH) VER=$(VER) OPTS="$(OPTS)" NET_OPTS="$(NET_OPTS)" PKGS=$(PKGS) 
	@echo using $(PKGS_FILES)
	$(if $(findstring x86_64, $(PLATFORM)), , $(QEMU)) ./netinstall-cli-$(VER_NETINSTALL) $(OPTS) $(NET_OPTS) routeros-$(VER)-$(ARCH).npk $(PKGS_FILES)

service: all
	while :; do $(MAKE) run ARCH=$(ARCH) VER=$(VER); done

download: all
	@echo use 'make' to run netinstall after connecting $(IFACE) or $(CLIENTIP) to router

all: routeros-$(VER)-$(ARCH).npk netinstall-cli-$(VER_NETINSTALL) all_packages-$(ARCH)-$(VER).zip
	@echo finished download ARCH=$(ARCH) VER=$(VER) PKGS=$(PKGS) PLATFORM=$(PLATFORM)

dump: 
	@echo ARCH=$(ARCH) VER=$(VER) CHANNEL=$(CHANNEL)

clean:
	rm -rf *.npk *.zip *.tar.gz *.lock
	rm -f netinstall*
	rm -f LICENSE.txt

netinstall-$(VER_NETINSTALL).tar.gz:
	wget [https://download.mikrotik.com/routeros/$(VER_NETINSTALL)/netinstall-$(VER_NETINSTALL).tar.gz](https://download.mikrotik.com/routeros/$%28VER_NETINSTALL%29/netinstall-$%28VER_NETINSTALL%29.tar.gz)netinstall-cli-$(VER_NETINSTALL): netinstall-$(VER_NETINSTALL).tar.gz
	tar zxvf netinstall-$(VER_NETINSTALL).tar.gz
	mv netinstall-cli netinstall-cli-$(VER_NETINSTALL)
	touch netinstall-cli-$(VER_NETINSTALL)

routeros-$(VER)-$(ARCH).npk:
	wget [https://download.mikrotik.com/routeros/$(VER)/](https://download.mikrotik.com/routeros/$%28VER%29/)$@

all_packages-$(ARCH)-$(VER).zip:
	wget [https://download.mikrotik.com/routeros/$(VER)/](https://download.mikrotik.com/routeros/$%28VER%29/)$@
	unzip -o all_packages-$(ARCH)-$(VER).zip 

stable long-term testing: 
	$(MAKE) $(filter-out $@,$(MAKECMDGOALS)) CHANNEL=$@ ARCH=$(ARCH)

arm arm64 mipsbe mmips smips ppc tile x86: 
	$(MAKE) $(filter-out $@,$(MAKECMDGOALS)) CHANNEL=$(CHANNEL) ARCH=$@

nothing:
	while :; do sleep 3600; done
