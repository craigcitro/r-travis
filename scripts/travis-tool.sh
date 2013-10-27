#!/bin/bash
# -*- sh-basic-offset: 4; sh-indentation: 4 -*-
# Bootstrap an R/travis environment.

set -e

OS=$(uname -s)

Bootstrap() {
    if [ "Darwin" == "${OS}" ]; then
        BootstrapMac
    elif [ "Linux" == "${OS}" ]; then
        BootstrapLinux
    else
        echo "Unknown OS: ${OS}"
        exit 1
    fi
}

BootstrapLinux() {
    # Update first.
    sudo apt-get update -qq

    # Set up our CRAN mirror.
    sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu $(lsb_release -cs)/"
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
    sudo apt-get update -qq

    # Install R as well as littler.
    sudo apt-get install r-base-dev littler

    # Change permissions for /usr/local/lib/R/site-library
    sudo chmod 2777 /usr/local/lib/R /usr/local/lib/R/site-library

    # Install devtools.
    DevtoolsInstall
}

BootstrapMac() {
   # TODO(craigcitro): Figure out TeX in OSX+travis.

    # (petrifast) Commented out homebrew installation. Install from a binary instead.
    # Install R.
    #brew install r

    # Install from latest CRAN binary build for OS X
    wget http://cran.r-project.org/bin/macosx/R-latest.pkg  -O /tmp/R-latest.pkg

    echo "Installing OS X binary package for R"
    sudo installer -pkg "/tmp/R-latest.pkg" -target /

    ## Install devtools.
    DevtoolsInstall
}

# TODO(craigcitro): Consider making this optional (based on
# [comments](https://github.com/craigcitro/r-travis/pull/17)), and if
# so remove the installation calls in the `Bootstrap*` functions.
DevtoolsInstall() {
    # Install devtools.
    Rscript -e 'install.packages(c("devtools"), repos=c("http://cran.rstudio.com"))'
    Rscript -e 'library(devtools); library(methods); install_github("devtools")'
}

AptGetInstall() {
    # TODO(eddelbuettel): Test and clean up

    if [ "Linux" != "${OS}" ]; then
        echo "Wrong OS: ${OS}"
        exit 1
    fi

    if [ "" == "$*" ]; then
        echo "No arguments"
        exit 1
    fi

    echo "Installing $*"
    sudo apt-get install $*
}

RInstall() {
    if [ "" == "$*" ]; then
        echo "No arguments"
        exit 1
    fi

    for pkg in $*; do
        echo "Installing ${pkg}"
        Rscript -e 'install.packages("'${pkg}'", repos=c("http://cran.rstudio.com"))'
    done
}

GithubPackage() {
    # An embarrassingly awful script for calling install_github from a
    # .travis.yml.
    #
    # Note that bash quoting makes this annoying for any additional
    # arguments.

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
    Rscript -e "library(devtools); library(methods); options(repos = c(CRAN = 'http://cran.rstudio.com')); install_github(\"${PACKAGE_NAME}\"${ARGS})"
}

InstallDeps() {
    Rscript -e 'library(devtools); library(methods); options(repos = c(CRAN = "http://cran.rstudio.com")); devtools:::install_deps(dependencies = TRUE)'
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
