#!/bin/bash
set -eu

python_version=${1:?}
abi=arm64_x86_64
os=macOS

project_dir=$(dirname $(realpath $0))
downloads=$project_dir/downloads

# build short Python version
read python_version_major python_version_minor python_version_patch python_version_build < <(echo $python_version | sed -E 's/^([0-9]+)\.([0-9]+)(\.([0-9]+))?(.*)/\1 \2 \4 \5/')
if [[ $python_version =~ ^[0-9]+\.[0-9]+$ ]]; then
    python_version=$(curl --silent "https://www.python.org/ftp/python/" | sed -nr "s/^.*\"($python_version_major\.$python_version_minor\.[0-9]+)\/\".*$/\1/p" | sort -rV | head -n 1)
    echo "Python version fetched from python.org: $python_version"
else
    python_version=$python_version_major.$python_version_minor.$python_version_patch
fi
python_version_short=$python_version_major.$python_version_minor
python_version_int=$(($python_version_major * 100 + $python_version_minor))

echo "python_version: $python_version"
echo "python_version_short: $python_version_short"
echo "python_version_int: $python_version_int"
echo "python_version_major: $python_version_major"
echo "python_version_minor: $python_version_minor"
echo "python_version_patch: $python_version_patch"
echo "python_version_build: $python_version_build"

curl_flags="--disable --fail --location --create-dirs --progress-bar"
mkdir -p $downloads

#      Python
# ===============

build_dir=$project_dir/build/$os/$abi
python_build_dir=$project_dir/build/$os/$abi/python-$python_version
python_install=$project_dir/install/$os/$abi/python-$python_version
python_filename=Python-$python_version$python_version_build.tgz

if [ ! -f $downloads/$python_filename ]; then
    echo ">>> Download Python for $abi"
    curl $curl_flags -o $downloads/$python_filename \
        https://www.python.org/ftp/python/$python_version/$python_filename
else
    echo ">>> Python for $abi is already downloaded"
fi

echo ">>> Unpack Python for $abi"
rm -rf $build_dir
mkdir -p $build_dir
tar zxvf $downloads/$python_filename -C $build_dir
mv $build_dir/Python-$python_version$python_version_build $python_build_dir
touch $python_build_dir/configure

echo ">>> Configuring Python build environment for $abi"

# configure build environment
rm -rf $python_install
cd $python_build_dir

echo ">>> Configuring Python for $abi"
./configure \
    --enable-framework="$python_install" \
    --enable-universalsdk \
    --with-universal-archs=universal2 \
    --enable-ipv6 \
    --without-ensurepip \
	2>&1 | tee -a ../python-$python_version.config.log

echo ">>> Building Python for $abi"
make \
    2>&1 | tee -a ../python-$python_version.build.log

echo ">>> Installing Python for $abi"
make install \
    2>&1 | tee -a ../python-$python_version.install.log

echo ">>> Copying additional resources to a framework"
cp $project_dir/resources/module.modulemap $python_install/Python.framework/Headers

echo ">>> Converting .framework to .xcframework"
xcodebuild -create-xcframework -framework $python_install/Python.framework -output $python_install/Python.xcframework

# the end!