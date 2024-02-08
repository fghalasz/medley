#!/bin/bash
###############################################################################
#
#    em_build.sh - script to package the Medley file system into a series of
#        Emscripten preload-file packages and to packe these packages
#        together with a emscriptem Maiko and the medley.html startup
#        page to make a emscripten Medley release tar.
#
#    Frank Halasz 2024-02-07
#
#    Copyright 2024 by Interlisp.org
#
###############################################################################

# functions to discover what directory this script is being executed from
get_abs_filename() {
  # $1 : relative filename
  echo "$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
}

get_script_dir() {

    # call this with ${BASH_SOURCE[0]:-$0} as its (only) parameter

    # set -x

    local SCRIPT_PATH="$( get_abs_filename "$1" )";

    pushd . > '/dev/null';

    while [ -h "$SCRIPT_PATH" ];
    do
        cd "$( dirname -- "$SCRIPT_PATH"; )";
        SCRIPT_PATH="$( readlink -f -- "$SCRIPT_PATH"; )";
    done

    cd "$( dirname -- "$SCRIPT_PATH"; )" > '/dev/null';
    SCRIPT_PATH="$( pwd; )";

    popd  > '/dev/null';

    # set +x

    echo "${SCRIPT_PATH}"
}

SCRIPTDIR=$(get_script_dir "${BASH_SOURCE[0]:-$0}")

#
#
mkdir -p "${SCRIPTDIR}"/build
#
#
cd "${SCRIPTDIR}"
cd ../..
export MEDLEYDIR="$(pwd)"
#
#
cd "${MEDLEYDIR}"
if [ -d "../maiko" ]
then
  cd ../maiko
  MAIKODIR="$(pwd)"
elif [ -d "../../maiko" ]
then
  cd ../../maiko
  MAIKODIR="$(pwd)"
elif [ -d "./maiko" ]
then
  cd ./maiko
  MAIKODIR="$(pwd)"
else
  echo "Error: Cannot find maiko directory"
  echo "Exiting"
  exit 11
fi
if [ ! -d "${MAIKODIR}/emscripten.wasm_nl" ]
then
  echo "Error: empscripten.wasm_nl directory missing from ${MAIKODIR}"
  echo "Exiting"
  exit 12
fi
#
#
cd "${MEDLEYDIR}"
if [ -d "../notecards" ]
then
  cd ../notecards
  NCDIR="$(pwd)"
elif [ -d "../../notecards" ]
then
  cd ../../notecards
  NCDIR="$(pwd)"
else
  echo "Notecards directory not found"
  echo "Apps file system will not be created"
  NOAPPS="true"
fi
#
#
cd "${SCRIPTDIR}"
file_packager									\
    build/medleyfs.data 							\
    --js-output=build/medleyfs.js 						\
    --no-force 									\
    --use-preload-cache 							\
    --indexedDB-name=MEDLEY_PRELOAD_CACHE					\
    --preload 									\
        "${MEDLEYDIR}"/loadups/whereis.hash@medley/loadups/whereis.hash 		\
	"${MEDLEYDIR}"/greetfiles/MEDLEYDIR-INIT.LCOM@usr/local/lde/site-init.lisp\
	"${MEDLEYDIR}"/docs/@medley/docs 						\
	"${MEDLEYDIR}"/doctools/@medley/doctools 					\
	"${MEDLEYDIR}"/greetfiles/@medley/greetfiles 				\
	"${MEDLEYDIR}"/internal/@medley/internal 					\
	"${MEDLEYDIR}"/sources/@medley/sources 					\
	"${MEDLEYDIR}"/library/@medley/library 					\
	"${MEDLEYDIR}"/lispusers/@medley/lispusers				\
	"${MEDLEYDIR}"/fonts/@medley/fonts					\
    2>&1 | grep -v FORCE_FILESYSTEM

file_packager									\
    build/lisp_sysout.data 							\
    --js-output=build/lisp_sysout.js 						\
    --no-force 									\
    --use-preload-cache 							\
    --indexedDB-name=MEDLEY_PRELOAD_CACHE					\
    --preload 									\
        "${MEDLEYDIR}"/loadups/lisp.sysout@medley/loadups/lisp.sysout 		\
    2>&1 | grep -v FORCE_FILESYSTEM

file_packager									\
    build/full_sysout.data 							\
    --js-output=build/full_sysout.js 						\
    --no-force 									\
    --use-preload-cache 							\
    --indexedDB-name=MEDLEY_PRELOAD_CACHE					\
    --preload 									\
        "${MEDLEYDIR}"/loadups/full.sysout@medley/loadups/full.sysout 		\
    2>&1 | grep -v FORCE_FILESYSTEM

if [ -z "${NOAPPS}" ]
then
  file_packager									\
      build/apps_sysout.data 							\
      --js-output=build/apps_sysout.js 						\
      --no-force 								\
      --use-preload-cache 							\
      --indexedDB-name=MEDLEY_PRELOAD_CACHE					\
      --preload 								\
          "${MEDLEYDIR}"/loadups/apps.sysout@medley/loadups/apps.sysout 		\
      2>&1 | grep -v FORCE_FILESYSTEM

  file_packager									\
      build/appsfs.data 							\
      --js-output=build/appsfs.js						\
      --no-force 								\
      --use-preload-cache 							\
      --indexedDB-name=MEDLEY_PRELOAD_CACHE					\
      --preload 								\
          "${MEDLEYDIR}"/rooms@medley/rooms			 		\
          "${NCDIR}"@notecards							\
      2>&1 | grep -v FORCE_FILESYSTEM
fi
#
#
#
cd "${SCRIPTDIR}"
cp -p medley.html build
if [ -n "${NOAPPS}" ]
then
  sed -i -e 's/params.has("apps")/false/' build/medley.html
fi
#
#
#
cd "${SCRIPTDIR}"
cp -p "${MAIKODIR}"/emscripten.wasm_nl/* build
#
#
#
mkdir -p "${SCRIPTDIR}"/tar
cd "${SCRIPTDIR}"/build
tar -c -z -f "${SCRIPTDIR}"/tar/medley-full-emscripten.tgz *
#
#
#
echo "Done with Medley emscripten build"
exit 0

