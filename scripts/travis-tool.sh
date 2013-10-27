#!/bin/bash
# -*- sh-basic-offset: 4; sh-indentation: 4 -*-
# Bootstrap an R/travis environment.

set -e

OS=$(uname -s)
HAVE_DEVTOOLS="no"

Bootstrap() {
    RTRAVIS_CRAN_URL=${RTRAVIS_CRAN_URL:-"http://cran.rstudio.com"}

    if [ "Darwin" == "${OS}" ]; then
        BootstrapMac
    elif [ "Linux" == "${OS}" ]; then
        BootstrapLinux
    else
        echo "Unknown OS: ${OS}"
        exit 1
    fi

    echo '^travis-tool\.sh$' >> .Rbuildignore

    echo "options(repos = c(CRAN = '"${RTRAVIS_CRAN_URL}"'))" | sudo tee /usr/lib/R/etc/Rprofile.site
}

BootstrapLinux() {
    # Set up our CRAN mirror.
    sudo add-apt-repository "deb ${RTRAVIS_CRAN_URL}/bin/linux/ubuntu $(lsb_release -cs)/"
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9

    # Update after adding all repositories.
    sudo apt-get update -qq

    # Install R (but not yet littler)
    sudo apt-get install r-base-dev 

    # Change permissions for /usr/local/lib/R/site-library
    sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library
}

BootstrapMac() {
    # TODO(craigcitro): Figure out TeX in OSX+travis.

    # Install from latest CRAN binary build for OS X
    wget ${RTRAVIS_CRAN_URL}/bin/macosx/R-latest.pkg  -O /tmp/R-latest.pkg

    echo "Installing OS X binary package for R"
    sudo installer -pkg "/tmp/R-latest.pkg" -target /
}

DevtoolsInstall() {
    # Install devtools.
    Rscript -e 'install.packages(c("devtools"))'
    Rscript -e 'library(devtools); library(methods); install_github("devtools")'
    # Mark installation
    HAVE_DEVTOOLS="yes"
}

AptGetInstall() {
    if [ "Linux" != "${OS}" ]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [ "" == "$*" ]; then
        echo "No arguments"
        exit 1
    fi

    echo "AptGetInstall: Installing $*"
    sudo apt-get install $*
}

RInstall() {
    if [ "" == "$*" ]; then
        echo "No arguments"
        exit 1
    fi

    echo "RInstall: Installing ${pkg}"
    Rscript -e 'install.packages(commandArgs(TRUE))' --args $*
}

GithubPackage() {
    # An embarrassingly awful script for calling install_github from a
    # .travis.yml.
    #
    # Note that bash quoting makes this annoying for any additional
    # arguments.

    if [ "no" == "${HAVE_DEVTOOLS}" ]; then
        DevtoolsInstall
    fi

    # Get the package name and strip it
    PACKAGE_NAME=$1
    shift

    # Join the remaining args.
    ARGS=$(echo $* | sed -e 's/ /, /g')
    if [ -n "${ARGS}" ]; then
        ARGS=", ${ARGS}"
    fi

    echo "Installing package: ${PACKAGE_NAME}"
    # Install the package.
    Rscript -e "library(devtools); library(methods); install_github(\"${PACKAGE_NAME}\"${ARGS})"
}

InstallDeps() {
    if [ "no" == "${HAVE_DEVTOOLS}" ]; then
        DevtoolsInstall
    fi

    Rscript -e 'library(devtools); library(methods); devtools:::install_deps(dependencies = TRUE)'
}

RunTests() {
    R CMD build --no-build-vignettes .
    FILE=$(ls -1 *.tar.gz)
    R CMD check "${FILE}" --no-manual --as-cran
    exit $?
}

COMMAND=$1
echo "Running command ${COMMAND}"
shift
case $COMMAND in
    "bootstrap")
        Bootstrap
        ;;
    "devtools_install") 
        DevtoolsInstall 
        ;;
    "aptget_install") 
        AptGetInstall "$*"
        ;;
    "r_install") 
        RInstall "$*"
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
