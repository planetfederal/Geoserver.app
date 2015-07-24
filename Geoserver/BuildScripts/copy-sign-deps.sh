#!/bin/bash

ORIG_INSTALL_ROOT="${PROJECT_DIR}/Geoserver/Vendor/geoserver"
EXECUTABLE_TARGET_DIR="$BUILT_PRODUCTS_DIR/$EXECUTABLE_FOLDER_PATH"
RESOURCES_TARGET_DIR="$BUILT_PRODUCTS_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH"

#copy include, share, geoserver, jre (to Resources for codesigning, then symlink into MacOS dir)
#cp -afR "${ORIG_INSTALL_ROOT}/include" "${ORIG_INSTALL_ROOT}/share" "${ORIG_INSTALL_ROOT}/gs" "$EXECUTABLE_TARGET_DIR/"
cp -afR "${ORIG_INSTALL_ROOT}/jetty" "$RESOURCES_TARGET_DIR/"
ln -sf ../Resources/jetty "$EXECUTABLE_TARGET_DIR/jetty"
cp -afR "${ORIG_INSTALL_ROOT}/jre" "$RESOURCES_TARGET_DIR/"
ln -sf ../Resources/jre "$EXECUTABLE_TARGET_DIR/jre"

# copy gdal dynamic libraries only (no need for static libraries)
cd "${ORIG_INSTALL_ROOT}/lib/"
mkdir -p "$RESOURCES_TARGET_DIR/jetty/gdal/"
cp -af *.dylib "$RESOURCES_TARGET_DIR/jetty/gdal/"


# fix dylib paths
cd "$RESOURCES_TARGET_DIR"
prefix="${ORIG_INSTALL_ROOT}"
prefix_length=${#prefix}
prefix_lib="${ORIG_INSTALL_ROOT}/lib"
prefix_lib_length=${#prefix_lib}

# fix library ids
for libfile in "jetty/gdal/"*
do
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
  linked_libs=$(otool -L $file | egrep --only-matching "\Q$prefix\E\S+");
  for lib_path in $linked_libs
  do
    new_lib_path="@loader_path"${lib_path:$prefix_lib_length}
    install_name_tool -change "$lib_path" "$new_lib_path" $file
  done
done

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

echo "Find and sign JRE code..."
FIND_AND_SIGN_CODE ./jre
echo "Find and sign Jetty code..."
FIND_AND_SIGN_CODE ./jetty

