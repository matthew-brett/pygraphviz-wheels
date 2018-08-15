# Define custom utilities
# Test for OSX with [ -n "$IS_OSX" ]
FREETYPE_VERSION=2.9.1
LIBUUID_VERSION=1.0.3
FONTCONFIG_VERSION=2.13.0
PKG_CONFIG_VERSION=0.29.2
EXPAT_TAG=50f4e16
GRAPHVIZ_COMMIT=f54ac2c9  # 2.38
GPERF_VERSION=3.1

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
    if [ -e ${FUNCNAME[0]}-stamp ]; then
        return
    fi
    if [ -n "$IS_OSX" ]; then
        brew upgrade autoconf automake libtool || true
    fi
    touch ${FUNCNAME[0]}-stamp
}

function upgrade_pkg_config {
    if [ -e ${FUNCNAME[0]}-stamp ]; then
        return
    fi
    if [ -z "$IS_OSX" ]; then
        build_simple pkg-config $PKG_CONFIG_VERSION https://pkg-config.freedesktop.org/releases tar.gz --with-internal-glib
    fi
    touch ${FUNCNAME[0]}-stamp
}

function build_flex {
    if [ -e ${FUNCNAME[0]}-stamp ]; then
        return
    fi
    if [ -z "$IS_OSX" ]; then
        yum install -y flex
    fi
    touch ${FUNCNAME[0]}-stamp
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
    build_expat
    upgrade_pkg_config
    build_flex
    git clone https://gitlab.com/graphviz/graphviz.git
    (cd graphviz \
        && git checkout $GRAPHVIZ_COMMIT \
        && ./autogen.sh \
        && ./configure --prefix=$BUILD_PREFIX --enable-php=no \
                --enable-python=no --enable-perl=no \
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
    if [ -z "$IS_OSX" ]; then
        # Still need graphviz command line utilities for tests
        apt-get install -y graphviz
    fi
    python --version
    nosetests pygraphviz
}
