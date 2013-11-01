#!/bin/bash
# -*- sh-basic-offset: 4; sh-indentation: 4 -*-
# Bootstrap an R/travis environment.

set -e

OS=$(uname -s)
CRAN=${CRAN:-"http://cran.rstudio.com"}

Bootstrap() {
    if [ "Darwin" == "${OS}" ]; then
        BootstrapMac
    elif [ "Linux" == "${OS}" ]; then
        BootstrapLinux
    else
        echo "Unknown OS: ${OS}"
        exit 1
    fi

    if ! (test -e .Rbuildignore && grep -q 'travis-tool' .Rbuildignore); then
        echo '^travis-tool\.sh$' >>.Rbuildignore
    fi
}

BootstrapLinux() {
    # Set up our CRAN mirror.
    sudo add-apt-repository "deb ${CRAN}/bin/linux/ubuntu $(lsb_release -cs)/"
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

    # Add marutter's c2d4u repository.
    sudo add-apt-repository -y "ppa:marutter/rrutter"
    sudo add-apt-repository -y "ppa:marutter/c2d4u"

    # Update after adding all repositories.
    sudo apt-get update -qq

    # Install an R development environment
    sudo apt-get install r-base-dev

    # Change permissions for /usr/local/lib/R/site-library
    # This should really be via 'staff adduser travis staff'
    # but that may affect only the next shell
    sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library
}

BootstrapMac() {
    # TODO(craigcitro): Figure out TeX in OSX+travis.

    # Install from latest CRAN binary build for OS X
    wget ${CRAN}/bin/macosx/R-latest.pkg  -O /tmp/R-latest.pkg

    echo "Installing OS X binary package for R"
    sudo installer -pkg "/tmp/R-latest.pkg" -target /
}

EnsureDevtools() {
    if ! Rscript -e 'if (!("devtools" %in% rownames(installed.packages()))) q(status=1)' ; then
        # Install devtools and testthat.
        if [ "Linux" == "${OS}" ]; then
            RBinaryInstall devtools testthat
        else
            RInstall devtools testthat
        fi
        # Bootstrap devtools to the live version on github.
        Rscript -e 'library(devtools); library(methods); install_github("devtools")'
    fi
}

AptGetInstall() {
    if [ "Linux" != "${OS}" ]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [ "" == "$*" ]; then
        echo "No arguments to aptget_install"
        exit 1
    fi

    echo "Installing apt package(s) $*"
    sudo apt-get install $*
}

RInstall() {
    if [ "" == "$*" ]; then
        echo "No arguments to r_install"
        exit 1
    fi

    echo "Installing R package(s): ${pkg}"
    Rscript -e 'install.packages(commandArgs(TRUE), repos="'"${CRAN}"'")' $*
}

RBinaryInstall() {
    if [ "Linux" != "${OS}" ]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [[ -z "$#" ]]; then
        echo "No arguments to r_binary_install"
        exit 1
    fi

    for r_package in $*; do
        echo "Installing *binary* R package: ${r_package}"
        r_deb="r-cran-$(echo "${r_package}" | tr '[:upper:]' '[:lower:]')"
        sudo apt-get install "${r_deb}"
    done
}

GithubPackage() {
    # An embarrassingly awful script for calling install_github from a
    # .travis.yml.
    #
    # Note that bash quoting makes this annoying for any additional
    # arguments.

    EnsureDevtools

    # Get the package name and strip it
    PACKAGE_NAME=$1
    shift

    # Join the remaining args.
    ARGS=$(echo $* | sed -e 's/ /, /g')
    if [ -n "${ARGS}" ]; then
        ARGS=", ${ARGS}"
    fi

    echo "Installing github package: ${PACKAGE_NAME}"
    # Install the package.
    Rscript -e 'library(devtools); library(methods); options(repos=c(CRAN="'"${CRAN}"'")); install_github("'"${PACKAGE_NAME}"'"'"${ARGS}"')'
}

InstallDeps() {
    EnsureDevtools
    Rscript -e 'library(devtools); library(methods); options(repos=c(CRAN="'"${CRAN}"'")); devtools:::install_deps(dependencies = TRUE)'
}

RunTests() {
    R CMD build --no-build-vignettes .
    FILE=$(ls -1 *.tar.gz)
    R CMD check "${FILE}" --no-manual --as-cran
    RES=$?
    out_path='*.Rcheck/tests/*.Rout*'
    if test -e ${out_path}; then
        cat "${out_path}"
    fi
    exit $RES
}

COMMAND=$1
echo "Running command: ${COMMAND}"
shift
case $COMMAND in
    "bootstrap")
        Bootstrap
        ;;
    "devtools_install")
        # TODO(craigcitro): Delete this function, since we don't need it.
        echo '***** devtools_install is deprecated and will soon disappear. *****'
        ;;
    "aptget_install")
        AptGetInstall "$*"
        ;;
    "r_install")
        RInstall "$*"
        ;;
    "r_binary_install")
        RBinaryInstall "$*"
        ;;
    "github_package")
        GithubPackage "$*"
        ;;
    "install_deps")
        InstallDeps
        ;;
    "run_tests")
        RunTests
        ;;
esac
