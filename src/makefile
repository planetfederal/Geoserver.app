# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4-SNAPSHOT
GDAL_VERSION=1.11.1

# EE vs Basic
ifeq ($(PROFILE),ee)
        SUITE_BIN_ZIP=suite-bin-${REV}-ee.zip
        SUITE_DOC_ZIP=suite-docs-${REV}-ee.zip
else
        SUITE_BIN_ZIP=suite-bin-${REV}.zip
        SUITE_DOC_ZIP=suite-docs-${REV}.zip
endif

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

all: jre geoserver gdal docs
clean: clean-jre clean-geoserver clean-libgdal clean-docs

#########################
###### GeoServer ########
#########################

geoserver: $(PREFIX)/jetty

$(PREFIX)/jetty: ${SUITE_BIN_ZIP}
	mkdir geoserver-${REV}
	unzip -d geoserver-${REV} -qq -o ${SUITE_BIN_ZIP}
	rm -rf ${PREFIX}/jetty
	mkdir -p ${PREFIX}
	(cd geoserver-${REV}/webapps; cp -r root dashboard)
	mv geoserver-${REV} ${PREFIX}/jetty
	touch $@

${SUITE_BIN_ZIP}:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/bin/${SUITE_BIN_ZIP}"
	
clean-geoserver:
	rm -Rf suite-bin-*
	rm -Rf geoserver-*
	
#########################
######## Docs ###########
#########################

docs: $(PREFIX)/jetty/webapps/opengeo-docs

$(PREFIX)/jetty/webapps/opengeo-docs: ${SUITE_DOC_ZIP}
	mkdir suite-docs-${REV}
	unzip -d suite-docs-${REV} -qq -o ${SUITE_DOC_ZIP}
	mv suite-docs-${REV}/opengeo-docs ${PREFIX}/jetty/webapps
	touch $@

${SUITE_DOC_ZIP}:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/docs/${SUITE_DOC_ZIP}"
	
clean-docs:
	rm -Rf suite-docs-*
	

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
	cp /opt/qgis_deps/lib/libltidsdk*.dylib $(PREFIX)/lib
	cp /opt/qgis_deps/lib/libtbb.dylib $(PREFIX)/lib
	cp gdal-$(GDAL_VERSION)/swig/java/*.jar $(PREFIX)/jetty/webapps/geoserver/WEB-INF/lib
	touch $@

gdal-$(GDAL_VERSION)/GNUMakefile: gdal-$(GDAL_VERSION)/autogen.sh
	cd gdal-$(GDAL_VERSION) && ./configure --prefix="$(PREFIX)" --with-mrsid=/opt/qgis_deps
	touch $@

gdal-$(GDAL_VERSION)/autogen.sh: gdal-${GDAL_VERSION}.tar.gz
	$(TAR) gdal-${GDAL_VERSION}.tar.gz
	touch $@	

gdal-${GDAL_VERSION}.tar.gz:
	$(CURL) "http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"
	touch $@

clean-libgdal:
	rm -Rf gdal-$(GDAL_VERSION)
