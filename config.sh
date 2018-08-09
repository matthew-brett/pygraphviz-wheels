# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
FREETYPE_VERSION=2.9.1
LIBUUID_VERSION=1.0.3
FONTCONFIG_VERSION=2.13.0
BZIP2_VERSION="${BZIP2_VERSION:-1.0.6}"
# BZIP website was down when I checked on August 8 2018
BZIP_URL=https://web.archive.org/web/20180624184806/http://bzip.org
EXPAT_TAG=50f4e16
GRAPHVIZ_TAG=stable_release_2.40.1
GPERF_VERSION=3.1

function build_bzip2 {
    if [ -n "$IS_OSX" ]; then return; fi  # OSX has bzip2 libs already
    if [ -e bzip2-stamp ]; then return; fi
    fetch_unpack $BZIP_URL/${BZIP2_VERSION}/bzip2-${BZIP2_VERSION}.tar.gz
    (cd bzip2-${BZIP2_VERSION} \
        && make -f Makefile-libbz2_so \
        && make install PREFIX=$BUILD_PREFIX)
    touch bzip2-stamp
}

function build_libuuid {
    build_simple libuuid $LIBUUID_VERSION https://download.sourceforge.net/libuuid
}

function build_gperf {
    build_simple gperf $GPERF_VERSION https://mirrors.kernel.org/gnu/gperf
}

function build_fontconfig {
    build_freetype
    build_libuuid
    build_gperf
    build_simple fontconfig $FONTCONFIG_VERSION https://www.freedesktop.org/software/fontconfig/release
}

function latest_autotools {
    if [ -e latest-autotools-stamp ]; then
        return
    fi
    if [ -n "$IS_OSX" ]; then
        brew upgrade autoconf automake libtool || true
    fi
    touch latest-autotools-stamp
}

function build_expat {
    if [ -e expat-stamp ]; then
        return
    fi
    latest_autotools
    local out_dir=$(fetch_unpack "https://github.com/libexpat/libexpat/archive/${EXPAT_TAG}.tar.gz")
    (cd $out_dir/expat \
        && ./buildconf.sh \
        && ./configure --without-xmlwf --without-docbook --prefix=$BUILD_PREFIX \
        && make \
        && make install)
    touch expat_stamp
}

function build_graphviz {
    if [ -e graphviz-stamp ]; then
        return
    fi
    build_swig
    build_freetype
    build_fontconfig
    echo "Finished fontconfig"
    build_expat
    echo "Finished expat"
    # Unfortunately, this always gives the latest version
    local out_dir=$(fetch_unpack https://graphviz.gitlab.io/pub/graphviz/stable/SOURCES/graphviz.tar.gz)
    (cd $out_dir \
        && ./configure --prefix=$BUILD_PREFIX --enable-php=no \
        && make \
        && make install)
    touch graphviz-stamp
}

function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    build_graphviz
}

function run_tests {
    # Runs tests on installed distribution from an empty directory
    python --version
    nosetests pygraphviz
}
