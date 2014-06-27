# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4-SNAPSHOT
GDAL_VERSION=1.9.2

#path configuration
PREFIX=$(PROJECT_DIR)/Geoserver/Vendor/geoserver
PATH=$(PREFIX)/bin:/bin:/usr/bin:/opt/local/bin

# Force compilers to use OS X 10.7 SDK for better compatibility with older systems
MIN_OSX=10.7
CFLAGS:=$(CFLAGS) -mmacosx-version-min=$(MIN_OSX)
CXXFLAGS:=$(CXXFLAGS) -mmacosx-version-min=$(MIN_OSX)
MACOSX_DEPLOYMENT_TARGET=$(MIN_OSX)

export CFLAGS CXXFLAGS MACOSX_DEPLOYMENT_TARGET

# commands used for downloading and extracting sources
CURL=/usr/bin/curl -L10 --silent --show-error --remote-name
TAR=/usr/bin/tar xzf

all: geoserver gdal
clean: clean-geoserver clean-libgdal

#########################
###### GeoServer ########
#########################

geoserver: $(PREFIX)/jetty

$(PREFIX)/jetty: opengeosuite-${REV}-bin.zip
	unzip -qq -o opengeosuite-${REV}-bin.zip
	rm -rf ${PREFIX}/jetty
	mkdir -p ${PREFIX}
	(cd opengeosuite-${SUITE_VERSION}/webapps; cp -r root dashboard)
	mv opengeosuite-${SUITE_VERSION} ${PREFIX}/jetty
	touch $@

opengeosuite-${REV}-bin.zip:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/bin/suite-bin-${REV}.zip
	
clean-geoserver:
	rm -Rf suite-bin-*

#########################
#######  libgdal  #######
#########################

gdal: geoserver $(PREFIX)/lib/libgdal.dylib

$(PREFIX)/lib/libgdal.dylib: gdal-$(GDAL_VERSION)/GNUMakefile
	(cd gdal-$(GDAL_VERSION); make install)
	cp java.opt gdal-$(GDAL_VERSION)/swig/java
	(cd gdal-$(GDAL_VERSION)/swig/java; make)
	cp gdal-$(GDAL_VERSION)/swig/java/.libs/*.dylib $(PREFIX)/lib
	cp gdal-$(GDAL_VERSION)/swig/java/*.jar $(PREFIX)/jetty/webapps/geoserver/WEB-INF/lib
	rm opengeosuite-*/gdal-*.jar
	cp opengeosuite-*/*.jar $(PREFIX)/jetty/webapps/geoserver/WEB-INF/lib
	touch $@

gdal-$(GDAL_VERSION)/GNUMakefile: gdal-$(GDAL_VERSION)/autogen.sh
	cd gdal-$(GDAL_VERSION) && ./configure --prefix="$(PREFIX)"
	touch $@

gdal-$(GDAL_VERSION)/autogen.sh: opengeosuite-${REV}-gdal.zip
	$(TAR) gdal-${GDAL_VERSION}.tar.gz
	unzip -qq -o suite-geoserver-ext-${REV}.zip
	touch $@	

suite-geoserver-ext-${REV}.zip:
	$(CURL) "http://download.osgeo.org/gdal/gdal-${GDAL_VERSION}.tar.gz"
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/geoserver-ext/suite-geoserver-ext-${REV}.zip"
	touch $@

clean-libgdal:
	rm -Rf gdal-$(GDAL_VERSION)
	rm -Rf suite-geoserver-ext-${REV}*
