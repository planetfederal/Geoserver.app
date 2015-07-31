# REQUIRES env vars: SUITE_REV, SUITE_CAT, PROJECT_DIR, PREFIX

# VERSION numbers
REV=$(SUITE_REV)
CAT=$(SUITE_CAT)
SUITE_VERSION=4.6
GDAL_VERSION=1.11.1
MRSID_MAJOR_VERSION=9
MRSID_VERSION="$(MRSID_MAJOR_VERSION).1.0.4045"

# EE vs Basic
ifeq ($(PROFILE),ee)
	SUITE_BIN_ZIP=suite-bin-${REV}-ee.zip
else
	SUITE_BIN_ZIP=suite-bin-${REV}.zip
endif

#path configuration
PREFIX=$(PROJECT_DIR)/Geoserver/Vendor/geoserver
PATH=$(PREFIX)/bin:/bin:/usr/bin:/usr/local/bin

# Force compilers to use OS X 10.9 SDK for better compatibility with older systems
MIN_OSX=10.9
CFLAGS:=$(CFLAGS) -mmacosx-version-min=$(MIN_OSX)
CXXFLAGS:=$(CXXFLAGS) -mmacosx-version-min=$(MIN_OSX)
MACOSX_DEPLOYMENT_TARGET=$(MIN_OSX)

export CFLAGS CXXFLAGS MACOSX_DEPLOYMENT_TARGET

CORES=$(shell /usr/sbin/sysctl -n hw.ncpu)

# commands used for downloading and extracting sources
CURL=/usr/bin/curl -L10 --silent --show-error --remote-name
TAR=/usr/bin/tar xzf

all: jre geoserver gdal wpsbuilder
clean: clean-geoserver
clean-deps: clean-jre clean-libgdal

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
	rm ${PREFIX}/jetty/webapps/geoserver/WEB-INF/lib/gt-geopkg-*.jar
	touch $@

${SUITE_BIN_ZIP}:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/bin/${SUITE_BIN_ZIP}"

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
	touch gdal-$(GDAL_VERSION)/config.rpath
	chmod u+x gdal-$(GDAL_VERSION)/config.rpath
	make -j $(CORES) -C gdal-$(GDAL_VERSION)
	make -C gdal-$(GDAL_VERSION) install
	# generate java bindings
	cp java.opt gdal-$(GDAL_VERSION)/swig/java
	(cd gdal-$(GDAL_VERSION)/swig/java; make)
	cp gdal-$(GDAL_VERSION)/swig/java/.libs/*.dylib $(PREFIX)/lib
	cp gdal-$(GDAL_VERSION)/swig/java/*.jar $(PREFIX)/jetty/webapps/geoserver/WEB-INF/lib
	mkdir -p ${PREFIX}/apps
	cp gdal-$(GDAL_VERSION)/swig/java/build/apps/gdalinfo.class ${PREFIX}/apps
	cp gdal-$(GDAL_VERSION)/swig/java/build/apps/ogrinfo.class ${PREFIX}/apps
	touch $@

gdal-$(GDAL_VERSION)/GNUMakefile: mrsid gdal-$(GDAL_VERSION)/autogen.sh
	cd gdal-$(GDAL_VERSION) && ./configure --prefix="$(PREFIX)" --with-mrsid="$(PREFIX)" --without-pg --without-pcre
	touch $@

gdal-$(GDAL_VERSION)/autogen.sh: gdal-${GDAL_VERSION}.tar.gz
	$(TAR) gdal-${GDAL_VERSION}.tar.gz
	touch $@

gdal-${GDAL_VERSION}.tar.gz:
	$(CURL) "http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz"
	touch $@

clean-libgdal:
	rm -Rf gdal-$(GDAL_VERSION)

#########################
########  MrSID  ########
#########################

mrsid: $(PREFIX)/lib/libltidsdk.dylib

$(PREFIX)/lib/libltidsdk.dylib: MrSID_Raster_DSDK-$(MRSID_VERSION).zip
	unzip -d $(PREFIX) -qq -o MrSID_Raster_DSDK-$(MRSID_VERSION).zip
	install_name_tool -id "$(PREFIX)/lib/libltidsdk.$(MRSID_MAJOR_VERSION).dylib" "$(PREFIX)/lib/libltidsdk.$(MRSID_MAJOR_VERSION).dylib"
	install_name_tool -id "$(PREFIX)/lib/libtbb.dylib" "$(PREFIX)/lib/libtbb.dylib"
	touch $@

MrSID_Raster_DSDK-$(MRSID_VERSION).zip:
	$(CURL) "http://r2d2.opengeo.org/suite/osx/libs/MrSID_Raster_DSDK-$(MRSID_VERSION).zip"

#########################
###### WPS Builder ######
#########################

wpsbuilder: $(PREFIX)/jetty/webapps/wpsbuilder

$(PREFIX)/jetty/webapps/wpsbuilder: suite-wpsbuilder-${REV}.zip
	rm -rf ${PREFIX}/jetty/webapps/wpsbuilder
	unzip -d ${PREFIX}/jetty/webapps/ -qq -o suite-wpsbuilder-${REV}.zip
	touch $@

suite-wpsbuilder-${REV}.zip:
	$(CURL) "http://r2d2.boundlessgeo.com/suite/core/${BRANCH}/${CAT}/wpsbuilder/suite-wpsbuilder-${REV}.zip"
