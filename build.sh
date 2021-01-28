#!/bin/bash

# packages you need for fedora. Worked with Fedora 33
# sudo dnf groupinstall "Development Tools"
# sudo dnf install curl alien nautilus-extensions rpmdevtools

set -eu

BUILD_DIR="_build"

rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR
cd $BUILD_DIR

URL=$(\
    curl -s https://www.qnap.com/en/utilities/essentials | \
    grep 'http.*Qsync.*Ubuntu.*deb' -o \
)

echo "Parsed deb download url: ${URL}. Downloading..."

curl $URL -O

echo "Downloaded. Unpacking with alien..."

alien --scripts -r -g QNAPQsyncClientUbuntux64-*.deb
rm QNAPQsyncClientUbuntux64-*.deb

cd qnapqsyncclient*

mv usr/lib usr/lib64

echo "Patching RPMBuild spec..."

specfilenames='ls ./QNAPQsyncClient-*.spec'
for eachfile in $specfilenames
do
   echo $eachfile
   TARGET_SPEC=$eachfile 
done

echo $TARGET_SPEC

LINE=$(grep -no '%description' $TARGET_SPEC | cut  -f1 -d':')
sed -i "${LINE},\$d" $TARGET_SPEC

cat >> $TARGET_SPEC << EOM
# disable automatic dependency and provides generation with:
%define __find_provides %{nil}
%define __find_requires %{nil}
%define _use_internal_dependency_generator 0
Autoprov: 0
Autoreq: 0

Requires: nautilus-extensions

%description
QNAP Qsync Client for Ubuntu x64.

%files
#XXX need to move nautilus extensions
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.a"
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.la"
"/usr/lib64/nautilus/extensions-3.0/libnautilus-qsync.so"
"/usr/local/bin/QNAP/QsyncClient/"
"/usr/local/lib/QNAP/QsyncClient/"
"/usr/share/applications/QNAPQsyncClient.desktop"
"/usr/share/pixmaps/Qsync.png"
"/usr/share/nautilus-qsync/"
EOM

echo "Building rpm..."

rpmbuild -bb $TARGET_SPEC --buildroot ${PWD}

