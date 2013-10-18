# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4.0-SNAPSHOT
GDAL_VERSION=1.9.2

#path configuration
PREFIX=$(PROJECT_DIR)/Geoserver/Vendor/geoserver
PATH=$(PREFIX)/bin:/bin:/usr/bin:/opt/local/bin

# commands used for downloading and extracting sources
CURL=/usr/bin/curl -L10 --silent --show-error --remote-name
TAR=/usr/bin/tar xzf

all: geoserver sdk
clean: clean-geoserver clean-libgdal

#########################
###### GeoServer ########
#########################

geoserver: $(PREFIX)/jetty

$(PREFIX)/jetty: opengeosuite-${REV}-bin.zip #$(PREFIX)/lib/libgdal.dylib
	unzip -qq -o opengeosuite-${REV}-bin.zip
	rm -rf ${PREFIX}/jetty
	mkdir -p ${PREFIX}
	mv opengeosuite-${SUITE_VERSION} ${PREFIX}/jetty
	touch $@

opengeosuite-${REV}-bin.zip:
	$(CURL) "http://r2d2.opengeo.org/suite/${CAT}/${REV}/opengeosuite-${REV}-bin.zip"
	
clean-geoserver:
	rm -Rf "opengeo-${SUITE_VERSION}"

#########################
###### SDK       ########
#########################

sdk: $(PREFIX)/jetty/webapps/cargo

$(PREFIX)/jetty/webapps/cargo: opengeosuite-${REV}-sdk.zip $(PREFIX)/jetty/
	unzip -qq -o opengeosuite-${REV}-sdk.zip
	cp -r opengeosuite-${SUITE_VERSION}-sdk/jetty/webapps/cargo $(PREFIX)/jetty/webapps/
	cp opengeosuite-${SUITE_VERSION}-sdk/jetty/etc/deployrealm.properties ${PREFIX}/jetty/etc/deployrealm.properties
	touch $@

opengeosuite-${REV}-sdk.zip:
	$(CURL) "http://r2d2.opengeo.org/suite/${CAT}/${REV}/opengeosuite-${REV}-sdk.zip"
	
clean-sdk:
	rm -Rf "opengeo-${SUITE_VERSION}-sdk"


#########################
#######  libgdal  #######
#########################

libgdal: $(PREFIX)/lib/libgdal.dylib

$(PREFIX)/lib/libgdal.dylib: gdal-$(GDAL_VERSION)/GNUMakefile
	make -C gdal-$(GDAL_VERSION) install

gdal-$(GDAL_VERSION)/GNUMakefile: gdal-$(GDAL_VERSION)/autogen.sh
	cd gdal-$(GDAL_VERSION) && ./autogen.sh && ./configure --prefix="$(PREFIX)"
	touch $@

gdal-$(GDAL_VERSION)/autogen.sh: gdal-${GDAL_VERSION}.tar.gz
	$(TAR) gdal-${GDAL_VERSION}.tar.gz
	touch $@	

gdal-${GDAL_VERSION}.tar.gz:
	$(CURL) "http://download.osgeo.org/gdal/gdal-${GDAL_VERSION}.tar.gz"

clean-libgdal:
	rm -Rf gdal-$(GDAL_VERSION)
