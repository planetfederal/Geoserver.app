# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4-SNAPSHOT
GDAL_VERSION=1.11.1

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

all: jre geoserver gdal
clean: clean-jre clean-geoserver clean-libgdal

#########################
###### GeoServer ########
#########################

geoserver: $(PREFIX)/jetty

$(PREFIX)/jetty: suite-bin-${REV}.zip
	mkdir geoserver-${REV}
	unzip -d geoserver-${REV} -qq -o suite-bin-${REV}.zip
	rm -rf ${PREFIX}/jetty
	mkdir -p ${PREFIX}
	(cd geoserver-${REV}/webapps; cp -r root dashboard)
	mv geoserver-${REV} ${PREFIX}/jetty
	touch $@

suite-bin-${REV}.zip:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/bin/suite-bin-${REV}.zip"
	
clean-geoserver:
	rm -Rf suite-bin-*
	rm -Rf geoserver-*

#########################
###### Bundle JRE #######
#########################

jre: $(PREFIX)/jre

$(PREFIX)/jre: jre-7-osx.tar.gz
	$(TAR) jre-7-osx.tar.gz
	rm -rf ${PREFIX}/jre
	mkdir -p ${PREFIX}
	mv jre ${PREFIX}/jre
	touch $@

jre-7-osx.tar.gz:
	$(CURL) "http://r2d2.opengeo.org/suite/osx/libs/jre-7-osx.tar.gz"
	
clean-jre:
	rm -Rf jre*


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
	touch $@

gdal-$(GDAL_VERSION)/GNUMakefile: gdal-$(GDAL_VERSION)/autogen.sh
	cd gdal-$(GDAL_VERSION) && ./configure --prefix="$(PREFIX)"
	touch $@

gdal-$(GDAL_VERSION)/autogen.sh: gdal-${GDAL_VERSION}RC1.tar.gz
	$(TAR) gdal-${GDAL_VERSION}RC1.tar.gz
	touch $@	

gdal-${GDAL_VERSION}RC1.tar.gz:
	$(CURL) "http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}RC1.tar.gz"
	touch $@

clean-libgdal:
	rm -Rf gdal-$(GDAL_VERSION)
