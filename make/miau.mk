###########################################################
#
# miau
#
###########################################################

MIAU_SITE=http://aleron.dl.sourceforge.net/sourceforge/miau
MIAU_VERSION=0.5.3
MIAU_SOURCE=miau-$(MIAU_VERSION).tar.gz
MIAU_DIR=miau-$(MIAU_VERSION)
MIAU_UNZIP=zcat

MIAU_IPK_VERSION=7

MIAU_CONFFILES= /opt/etc/miau.conf \
		/opt/etc/init.d/S52miau \
		/opt/etc/logrotate.d/miau

MIAU_PATCHES=$(MIAU_SOURCE_DIR)/paths.patch

MIAU_CPPFLAGS=
MIAU_LDFLAGS=

MIAU_BUILD_DIR=$(BUILD_DIR)/miau
MIAU_SOURCE_DIR=$(SOURCE_DIR)/miau
MIAU_IPK_DIR=$(BUILD_DIR)/miau-$(MIAU_VERSION)-ipk
MIAU_IPK=$(BUILD_DIR)/miau_$(MIAU_VERSION)-$(MIAU_IPK_VERSION)_armeb.ipk

$(DL_DIR)/$(MIAU_SOURCE):
	$(WGET) -P $(DL_DIR) $(MIAU_SITE)/$(MIAU_SOURCE)

miau-source: $(DL_DIR)/$(MIAU_SOURCE) $(MIAU_PATCHES)

$(MIAU_BUILD_DIR)/.configured: $(DL_DIR)/$(MIAU_SOURCE)
	$(MIAU_UNZIP) $(DL_DIR)/$(MIAU_SOURCE) | tar -C $(BUILD_DIR) -xvf -
	cat $(MIAU_PATCHES) | patch -d $(BUILD_DIR)/$(MIAU_DIR) -p1
	mv $(BUILD_DIR)/$(MIAU_DIR) $(MIAU_BUILD_DIR)
	(cd $(MIAU_BUILD_DIR); \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(STAGING_CPPFLAGS) $(MIAU_CPPFLAGS)" \
		LDFLAGS="$(STAGING_LDFLAGS) $(MIAU_LDFLAGS)" \
		./configure \
		--build=$(GNU_HOST_NAME) \
		--host=$(GNU_TARGET_NAME) \
		--target=$(GNU_TARGET_NAME) \
		--prefix=/opt	\
		--enable-dccbounce \
		--enable-automode \
		--enable-releasenick \
		--enable-ctcp-replies \
		--enable-mkpasswd \
		--enable-uptime \
		--enable-chanlog \
		--enable-privlog \
		--enable-onconnect \
		--enable-empty-awaymsg \
		--enable-enduserdebug \
		--enable-pingstat \
		--enable-dumpstatus \
	)
	touch $(MIAU_BUILD_DIR)/.configured

miau-unpack: $(MIAU_BUILD_DIR)/.configured

$(MIAU_BUILD_DIR)/src/miau: $(MIAU_BUILD_DIR)/.configured
	$(MAKE) -C $(MIAU_BUILD_DIR)

miau: $(MIAU_BUILD_DIR)/src/miau

$(MIAU_IPK): $(MIAU_BUILD_DIR)/src/miau
	rm -rf $(MIAU_IPK_DIR) $(BUILD_DIR)/miau_*_armeb.ipk
	install -d $(MIAU_IPK_DIR)/opt/bin
	$(TARGET_STRIP) $(MIAU_BUILD_DIR)/src/miau -o $(MIAU_IPK_DIR)/opt/bin/miau
	install -d $(MIAU_IPK_DIR)/opt/etc
	install -m 644 $(MIAU_SOURCE_DIR)/miau.conf $(MIAU_IPK_DIR)/opt/etc/miau.conf
	install -d $(MIAU_IPK_DIR)/opt/etc/init.d
	install -m 755 $(MIAU_SOURCE_DIR)/rc.miau $(MIAU_IPK_DIR)/opt/etc/init.d/S52miau
	install -d $(MIAU_IPK_DIR)/opt/etc/logrotate.d
	install -m 755 $(MIAU_SOURCE_DIR)/logrotate.miau $(MIAU_IPK_DIR)/opt/etc/logrotate.d/miau
	install -d $(MIAU_IPK_DIR)/CONTROL
	install -m 644 $(MIAU_SOURCE_DIR)/control $(MIAU_IPK_DIR)/CONTROL/control
	install -m 644 $(MIAU_SOURCE_DIR)/postinst $(MIAU_IPK_DIR)/CONTROL/postinst
	install -m 644 $(MIAU_SOURCE_DIR)/prerm $(MIAU_IPK_DIR)/CONTROL/prerm
	echo $(MIAU_CONFFILES) | sed -e 's/ /\n/g' > $(MIAU_IPK_DIR)/CONTROL/conffiles
	cd $(BUILD_DIR); $(IPKG_BUILD) $(MIAU_IPK_DIR)

miau-ipk: $(MIAU_IPK)

miau-clean:
	-$(MAKE) -C $(MIAU_BUILD_DIR) clean

miau-dirclean:
	rm -rf $(BUILD_DIR)/$(MIAU_DIR) $(MIAU_BUILD_DIR) $(MIAU_IPK_DIR) $(MIAU_IPK)
