# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4.0-SNAPSHOT
GDAL_VERSION=1.9.2

#path configuration
PREFIX=$(CURDIR)/../Geoserver/Vendor/geoserver
PATH=$(PREFIX)/bin:/bin:/usr/bin:/opt/local/bin

# commands used for downloading and extracting sources
CURL=/usr/bin/curl -L10 --silent --show-error --remote-name
TAR=/usr/bin/tar xzf

all: geoserver
clean: clean-geoserver clean-libgdal

#########################
###### GeoServer ########
#########################

geoserver: $(PREFIX)/gs/geoserver

$(PREFIX)/gs/geoserver: opengeosuite-${REV}-bin.zip $(PREFIX)/lib/libgdal.dylib
	unzip -qq -o opengeosuite-${REV}-bin.zip
	cp -r opengeosuite-${SUITE_VERSION} ${PREFIX}/gs
	touch $@

opengeosuite-${REV}-bin.zip:
	$(CURL) "http://r2d2.opengeo.org/suite/${CAT}/${REV}/opengeosuite-${REV}-bin.zip"
	
clean-geoserver:
	rm -Rf "opengeo-${SUITE_VERSION}"

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
