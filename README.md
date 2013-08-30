# Geoserver.app

[Postgres.app](https://github.com/PostgresApp/PostgresApp) is the easiest way to get started with PostgreSQL on the Mac. Why not do something similar for GeoServer?

## Requirements
Geoserver.app requires Mac OS X 10.7 (Lion) or newer. Java is also required, but the OS should automatically prompt to install java if you don't have it.

## How to Use Geoserver.app

1. Double click on the Geoserver.app
2. Go to `http://localhost:8080/geoserver` in your favourite web browser
3. There is no step 3

## Where is the data_dir?
If you really need to muck with your data\_dir, you can find it in `~/Library/Containers/com.boundlessgeo.geoserver/Data/Library/Application Support/GeoServer/data_dir`. Yes this is pretty well hidden, but it follows Apple's sandboxing conventions and you really shouldn't be touching those xml files anyways.

## Build
Building GeoServer.app requires [Xcode 4](https://developer.apple.com/xcode/) or higher. 

If you want to build in the Xcode gui, you will first need to run `make` in the `src` directory with the `SUITE_REV` and `SUITE_CAT` environment variables set to the short git revision and build type (dev, release, etc...) for the version of the suite geoserver you need to bundle. For example:

    SUITE_REV=4e0a2f9 SUITE_CAT=dev make

will build all the dependancies for the geoserver bundle for suite revision `4e0a2f9`.

Once this step is done, you can build and run as usual in the Xcode GUI. You can also use `xcodebuild` to create a build in one step using the command line, Jenkins, or similar but this also requires setting the `SUITE_REV` and `SUITE_CAT` environment variables.