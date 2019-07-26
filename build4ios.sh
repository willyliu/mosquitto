#!/bin/bash
#
# Copyright 2016 leenjewel
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u

SOURCE="$0"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
pwd_path="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
 
# Setup architectures, library name and other vars + cleanup from previous runs
ARCHS=("arm" "i386" "x86_64")
SDKS=("iphoneos" "iphonesimulator" "iphonesimulator")
PLATFORMS=("iPhoneOS" "iPhoneSimulator" "iPhoneSimulator")
DEVELOPER=`xcode-select -print-path`
# If you can't compile with this version, please modify the version to it which on your mac.
MIN_IOS_VERSION="8.0"
LIB_DEST_DIR="${pwd_path}/output/ios/mosquitto-universal"
rm -rf "${LIB_DEST_DIR}"

# Unarchive library, then configure and make for specified architectures
configure_make()
{
   ARCH=$1; SDK=$2; PLATFORM=$3;
   BUILD_DIR="build_${ARCH}"
   if [ -d "${BUILD_DIR}" ]; then
       rm -fr "${BUILD_DIR}"
   fi
   mkdir -p "${BUILD_DIR}"
   pushd .; cd "${BUILD_DIR}";

   PREFIX_DIR="${pwd_path}/output/ios/mosquitto-${ARCH}"
   if [ -d "${PREFIX_DIR}" ]; then
       rm -fr "${PREFIX_DIR}"
   fi
   mkdir -p "${PREFIX_DIR}"

    if [[ "${ARCH}" == "x86_64" ]]; then
        cmake -DCMAKE_TOOLCHAIN_FILE=ios.cmake -DIOS_DEPLOYMENT_TARGET=8.0 -DIOS_PLATFORM=SIMULATOR64 -DOPENSSL_INCLUDE_DIR=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/include/ -DOPENSSL_SSL_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libcrypto.a -DWITH_STATIC_LIBRARIES=ON -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX_DIR} ..   
    elif [[ "${ARCH}" == "i386" ]]; then
        cmake -DCMAKE_TOOLCHAIN_FILE=ios.cmake -DIOS_DEPLOYMENT_TARGET=8.0 -DIOS_PLATFORM=SIMULATOR -DOPENSSL_INCLUDE_DIR=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/include/ -DOPENSSL_SSL_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libcrypto.a -DWITH_STATIC_LIBRARIES=ON -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX_DIR} ..
    else
        cmake -DCMAKE_TOOLCHAIN_FILE=ios.cmake -DIOS_DEPLOYMENT_TARGET=8.0 -DOPENSSL_INCLUDE_DIR=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/include/ -DOPENSSL_SSL_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libssl.a -DOPENSSL_CRYPTO_LIBRARY=/Users/willyliu/Documents/projects/kklinx_client_sdk/SDK/src/lib/openssl/ios/lib/libcrypto.a -DWITH_STATIC_LIBRARIES=ON -DCMAKE_C_FLAGS=-fembed-bitcode -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX_DIR} ..
    fi
   
   make clean
   if make -j8
   then
       make install;
       popd;
   fi
}
for ((i=0; i < ${#ARCHS[@]}; i++))
do
    if [[ $# -eq 0 || "$1" == "${ARCHS[i]}" ]]; then
        configure_make "${ARCHS[i]}" "${SDKS[i]}" "${PLATFORMS[i]}"
    fi
done

# Combine libraries for different architectures into one
# Use .a files from the temp directory by providing relative paths
create_lib()
{
   LIB_SRC=$1; LIB_DST=$2;
   LIB_PATHS=( "${ARCHS[@]/#/${pwd_path}/output/ios/mosquitto-}" )
   LIB_PATHS=( "${LIB_PATHS[@]/%//lib/${LIB_SRC}}" )
   lipo ${LIB_PATHS[@]} -create -output "${LIB_DST}"
}
mkdir -p "${LIB_DEST_DIR}";
create_lib "libmosquitto.a" "${LIB_DEST_DIR}/libmosquitto.a"
lipo -info "${LIB_DEST_DIR}/libmosquitto.a"