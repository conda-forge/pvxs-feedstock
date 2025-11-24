#!/bin/bash

if [[ "$target_platform" == "osx-arm64" ]]; then
  export EPICS_HOST_ARCH="darwin-aarch64"
else
  export EPICS_HOST_ARCH=$(perl ${EPICS_BASE}/lib/perl/EpicsHostArch.pl)
fi

cat <<EOF > configure/RELEASE.local
EPICS_BASE=${EPICS_BASE}
EOF

if [[ "$target_platform" == osx* ]]; then
  cat << EOF >> configure/CONFIG_SITE.local
# Force EPICS to use its built-in command line library instead of readline
COMMANDLINE_LIBRARY=EPICS
EOF
fi

make -j${CPU_COUNT} install

install -d ${PREFIX}/include/pvxs ${PREFIX}/bin/ ${PREFIX}/lib/ ${PREFIX}/pvxs/dbd ${PREFIX}/pvxs/db
install bin/${EPICS_HOST_ARCH}/* ${PREFIX}/bin/
if [[ "$target_platform" == osx* ]]; then
  install lib/${EPICS_HOST_ARCH}/*.dylib* ${PREFIX}/lib/
else
  install lib/${EPICS_HOST_ARCH}/*.so* ${PREFIX}/lib/
fi
install -m 0664 include/pvxs/* ${PREFIX}/include/pvxs/
install -m 0664 dbd/* ${PREFIX}/pvxs/dbd
install -m 0664 db/* ${PREFIX}/pvxs/db

IFS='.' read -r MAJOR MINOR MAINTENANCE <<< "$PKG_VERSION"

mkdir -p $PREFIX/etc/conda/activate.d
cat <<EOF > $PREFIX/etc/conda/activate.d/pvxs_activate.sh
export PVXS="${PREFIX}/pvxs/"
export PVXS_MAJOR_VERSION="${MAJOR}"
export PVXS_MINOR_VERSION="${MINOR}"
export PVXS_MAINTENANCE_VERSION="${MAINTENANCE}"
EOF

mkdir -p $PREFIX/etc/conda/deactivate.d
cat <<EOF > $PREFIX/etc/conda/deactivate.d/pvxs_deactivate.sh
unset PVXS
unset PVXS_MAJOR_VERSION
unset PVXS_MINOR_VERSION
unset PVXS_MAINTENANCE_VERSION
EOF

if [[ "$target_platform" == osx* ]]; then
  # Fix install_name for all .dylib files in $PREFIX/lib
  for lib in "${PREFIX}/lib/"*.dylib*; do
    [ -e "$lib" ] || continue
    install_name_tool -id "@rpath/$(basename "$lib")" "$lib"
  done

  # Patch all binaries and libraries in $PREFIX/bin and $PREFIX/lib to use @rpath
  for bin in "${PREFIX}/bin/"* "${PREFIX}/lib/"*.dylib*; do
    [ -e "$bin" ] || continue
    otool -L "$bin" | awk '/libpvxs.*\.dylib/ {print $1}' | while read -r dep; do
      [ -z "$dep" ] && continue
      newname="@rpath/$(basename "$dep")"
      install_name_tool -change "$dep" "$newname" "$bin" || true
    done
  done
fi
