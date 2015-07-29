#!/bin/bash

ORIG_INSTALL_ROOT="${PROJECT_DIR}/Geoserver/Vendor/geoserver"
EXECUTABLE_TARGET_DIR="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"
RESOURCES_TARGET_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

pushd "${ORIG_INSTALL_ROOT}"

  #copy include, share, geoserver, jre (to Resources for codesigning, then symlink into MacOS dir)
  #cp -af "${ORIG_INSTALL_ROOT}/include" "${ORIG_INSTALL_ROOT}/share" "${ORIG_INSTALL_ROOT}/gs" "$EXECUTABLE_TARGET_DIR/"
  cp -af jetty "${RESOURCES_TARGET_DIR}/"
  ln -sf ../Resources/jetty "${EXECUTABLE_TARGET_DIR}/jetty"
  cp -af jre "${RESOURCES_TARGET_DIR}/"
  ln -sf ../Resources/jre "${EXECUTABLE_TARGET_DIR}/jre"

  # update the app's SUITE_VERSION with that from copied jetty/version.ini
  suite_ver=$(cat "${RESOURCES_TARGET_DIR}/jetty/version.ini" | grep 'suite_version' -m 1 | grep '[0-9].*' -o)
  /usr/libexec/PlistBuddy -c "Set :SuiteVersion $suite_ver" "${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

  # copy gdal dynamic libraries only (no need for static libraries)
  mkdir -p "${RESOURCES_TARGET_DIR}/jetty/gdal/"
  cp -af lib/*.dylib "${RESOURCES_TARGET_DIR}/jetty/gdal/"

  # copy basic gdal cmd line utilities and java apps, to later proof bundling and bindings of dylibs
  mkdir -p "${RESOURCES_TARGET_DIR}/jetty/gdal/bin/"
  cp -af bin/gdalinfo bin/ogrinfo "${RESOURCES_TARGET_DIR}/jetty/gdal/bin/"
  cp -af apps/gdalinfo.class apps/ogrinfo.class "${RESOURCES_TARGET_DIR}/jetty/gdal/bin/"

popd # $ORIG_INSTALL_ROOT

pushd "${RESOURCES_TARGET_DIR}"

  prefix="${ORIG_INSTALL_ROOT}"
  prefix_length=${#prefix}
  prefix_lib="${ORIG_INSTALL_ROOT}/lib"
  prefix_lib_length=${#prefix_lib}

  # fix library ids
  for libfile in "jetty/gdal/"*
  do
    if [ ! -f $libfile ]; then
      continue
    fi
    library_id=$(otool -D $libfile | grep "$prefix");
    if [[ -n "$library_id" ]]
    then
      new_library_id="@loader_path"${library_id:$prefix_lib_length}
      install_name_tool -id "$new_library_id" "$libfile"
    fi
  done

  # fix library references
  for file in "jetty/gdal/"*
  do
    if [ ! -f $file ]; then
      continue
    fi
    linked_libs=$(otool -L $file | egrep --only-matching "\Q$prefix\E\S+");
    for lib_path in $linked_libs
    do
      new_lib_path="@loader_path"${lib_path:$prefix_lib_length}
      install_name_tool -change "$lib_path" "$new_lib_path" $file
    done
  done
  for file in "jetty/gdal/bin/gdalinfo" "jetty/gdal/bin/ogrinfo"
  do
    linked_libs=$(otool -L $file | egrep --only-matching "\Q$prefix\E\S+");
    for lib_path in $linked_libs
    do
      new_lib_path="@loader_path/.."${lib_path:$prefix_lib_length}
      install_name_tool -change "$lib_path" "$new_lib_path" $file
    done
  done

  # add test script to ensure gdal libs are bundled right and bindings are good
  rm -f "jetty/gdal/bin/test-gdal.sh"

  pushd "${RESOURCES_TARGET_DIR}/jetty/gdal/bin"
    cat << EOF > "test-gdal.sh"
#!/bin/bash

echo "Testing bundled libraries..."
./gdalinfo --formats
./ogrinfo --formats

echo "Testing Java bindings to bundled libraries..."
export JAVA_HOME=$(/usr/libexec/java_home)
export DYLD_LIBRARY_PATH=..
java -classpath ../../webapps/geoserver/WEB-INF/lib/gdal.jar:. gdalinfo --formats
java -classpath ../../webapps/geoserver/WEB-INF/lib/gdal.jar:. ogrinfo --formats
EOF

    chmod u+x,go-rwx "test-gdal.sh"
    "./test-gdal.sh" > /dev/null || exit 1
  popd

popd # $RESOURCES_TARGET_DIR


# codesign copied Mach-O files and scripts
# security unlock -p $KEYCHAIN_PASSWORD $HOME/Library/Keychains/login.keychain

SIGN_FILE () {
  if [[ -z "${1}" ]]; then
    echo "No signing parameter passed"
    return
  fi
  #echo "${1}"
  codesign --force --keychain $HOME/Library/Keychains/login.keychain \
    --timestamp --verbose -s AD305D96B9F8DC4BAD13F046AF063BF8EC6EB8DE "${1}"
}

FIND_AND_SIGN_CODE () {
  if [[ -z "${1}" ]]; then
    echo "No directory parameter passed"
    return
  fi
  find "${1}" \! -type l -and -type f -print0 | while IFS= read -r -d $'\0' afile
  do
    if [[ "${afile}" = *.jar ]] || [[ "${afile}" = *.class ]]; then
      SIGN_FILE "${afile}"
      continue
    fi
    finfo=$(file "${afile}")
    if [[ $finfo =~ Mach-O || $finfo =~ POSIX[[:space:]]shell[[:space:]]script ]]; then
      SIGN_FILE "${afile}"
    fi
  done
}

pushd "$RESOURCES_TARGET_DIR"

  echo "Find and sign JRE code..."
  FIND_AND_SIGN_CODE ./jre
  echo "Find and sign Jetty code..."
  FIND_AND_SIGN_CODE ./jetty

popd
