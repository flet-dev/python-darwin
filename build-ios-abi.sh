#!/bin/bash
set -eu

python_version=${1:?}
abi=${2:?}

bzip2_version=1.0.8-1
xz_version=5.4.7-1
libffi_version=3.4.6-1
openssl_version=3.0.15-1

os=iOS
build=custom

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

case $abi in
    arm64-apple-ios)
        dependency_arch=iphoneos.arm64
        ;;
    arm64-apple-ios-simulator)
        dependency_arch=iphonesimulator.arm64
        ;;
    x86_64-apple-ios-simulator)
        dependency_arch=iphonesimulator.x86_64
        ;;
    *)
        fail "Unknown ABI: '$abi'"
        ;;
esac

# create VERSIONS support file
support_versions=$project_dir/support/$python_version_short/$os/VERSIONS
mkdir -p $(dirname $support_versions)
echo ">>> Create VERSIONS file for $os"
echo "Python version: $python_version " > $support_versions
echo "Build: $build" >> $support_versions
echo "---------------------" >> $support_versions
echo "libFFI: $libffi_version" >> $support_versions
echo "BZip2: $bzip2_version" >> $support_versions
echo "OpenSSL: $openssl_version" >> $support_versions
echo "XZ: $xz_version" >> $support_versions

#      BZip2
# ===============
bzip2_install=$project_dir/install/$os/$abi/bzip2-$bzip2_version
bzip2_lib=$bzip2_install/lib/libbz2.a
bzip2_filename=bzip2-$bzip2_version-$dependency_arch.tar.gz

if [ ! -f $downloads/$bzip2_filename ]; then
    echo ">>> Download BZip2 for $abi"
    curl $curl_flags -o $downloads/$bzip2_filename \
        https://github.com/beeware/cpython-apple-source-deps/releases/download/BZip2-$bzip2_version/$bzip2_filename
else
    echo ">>> BZip2 for $abi is already downloaded"
fi

echo ">>> Install BZip2 for $abi"
rm -rf $bzip2_install
mkdir -p $bzip2_install
tar zxvf $downloads/$bzip2_filename -C $bzip2_install
touch $bzip2_lib

#      XZ (LZMA)
# =================
xz_install=$project_dir/install/$os/$abi/xz-$xz_version
xz_lib=$xz_install/lib/liblzma.a
xz_filename=xz-$xz_version-$dependency_arch.tar.gz

if [ ! -f $downloads/$xz_filename ]; then
    echo ">>> Download XZ for $abi"
    curl $curl_flags -o $downloads/$xz_filename \
        https://github.com/beeware/cpython-apple-source-deps/releases/download/XZ-$xz_version/$xz_filename
else
    echo ">>> XZ for $abi is already downloaded"
fi

echo ">>> Install XZ for $abi"
rm -rf $xz_install
mkdir -p $xz_install
tar zxvf $downloads/$xz_filename -C $xz_install
touch $xz_lib

#      LibFFI
# =================
libffi_install=$project_dir/install/$os/$abi/libffi-$libffi_version
libffi_lib=$libffi_install/lib/libffi.a
libffi_filename=libffi-$libffi_version-$dependency_arch.tar.gz

if [ ! -f $downloads/$libffi_filename ]; then
    echo ">>> Download LibFFI for $abi"
    curl $curl_flags -o $downloads/$libffi_filename \
        https://github.com/beeware/cpython-apple-source-deps/releases/download/libFFI-$libffi_version/$libffi_filename
else
    echo ">>> LibFFI for $abi is already downloaded"
fi

echo ">>> Install LibFFI for $abi"
rm -rf $libffi_install
mkdir -p $libffi_install
tar zxvf $downloads/$libffi_filename -C $libffi_install
touch $libffi_lib

#      OpenSSL
# =================
openssl_install=$project_dir/install/$os/$abi/openssl-$openssl_version
openssl_lib=$openssl_install/lib/libssl.a
openssl_filename=openssl-$openssl_version-$dependency_arch.tar.gz

if [ ! -f $downloads/$openssl_filename ]; then
    echo ">>> Download OpenSSL for $abi"
    curl $curl_flags -o $downloads/$openssl_filename \
        https://github.com/beeware/cpython-apple-source-deps/releases/download/OpenSSL-$openssl_version/$openssl_filename
else
    echo ">>> OpenSSL for $abi is already downloaded"
fi

echo ">>> Install OpenSSL for $abi"
rm -rf $openssl_install
mkdir -p $openssl_install
tar zxvf $downloads/$openssl_filename -C $openssl_install
touch $openssl_lib

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
cd $python_build_dir
rm -rf $python_install

with_build_python_dir=$(which python)
export PATH="$python_build_dir/iOS/Resources/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin"

echo ">>> Configuring Python for $abi"
./configure \
    LIBLZMA_CFLAGS="-I$xz_install/include" \
    LIBLZMA_LIBS="-L$xz_install/lib -llzma" \
    BZIP2_CFLAGS="-I$bzip2_install/include" \
    BZIP2_LIBS="-L$bzip2_install/lib -lbz2" \
    LIBFFI_CFLAGS="-I$libffi_install/include" \
    LIBFFI_LIBS="-L$libffi_install/lib -lffi" \
    --with-openssl="$openssl_install" \
    --enable-framework="$python_install" \
    --host=$abi \
    --build=$(./config.guess) \
    --with-build-python=$with_build_python_dir \
    --enable-ipv6 \
    --without-ensurepip \
	2>&1 | tee -a ../python-$python_version.config.log

echo ">>> Building Python for $abi"
make \
    2>&1 | tee -a ../python-$python_version.build.log

echo ">>> Installing Python for $abi"
make install \
    2>&1 | tee -a ../python-$python_version.install.log

echo ">>> Create a non-executable stub binary python3"
echo "#!/bin/bash\necho Can\\'t run $(abi) binary\nexit 1" > $python_install/bin/python$python_version_short
chmod 755 $python_install/bin/python$python_version_short

echo ">>> Copying additional resources to a framework"
cp $project_dir/resources/module.modulemap $python_install/Python.framework/Headers

# the end!