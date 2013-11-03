#!/bin/bash
# -*- sh-basic-offset: 4; sh-indentation: 4 -*-
# Bootstrap an R/travis environment.

set -e

CRAN=${CRAN:-"http://cran.rstudio.com"}
OS=$(uname -s)

R_BUILD_ARGS=${R_BUILD_ARGS-"--no-build-vignettes"}
R_CHECK_ARGS=${R_CHECK_ARGS-"--no-manual --as-cran"}

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

    # Install an R development environment. qpdf is also needed for
    # --as-cran checks:
    #   https://stat.ethz.ch/pipermail/r-help//2012-September/335676.html
    sudo apt-get install r-base-dev qpdf

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

    r_packages=$*
    r_debs=$(for r_package in ${r_packages}; do
        r_deb="r-cran-$(echo "${r_package}" | tr '[:upper:]' '[:lower:]')"
        echo -n "${r_deb} "
    done)

    echo "Installing *binary* R packages: ${r_packages}"
    sudo apt-get install ${r_debs}
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

DumpLogsByExtension() {
    if [[ -z "$1" ]]; then
        echo "dump_logs_by_extension requires exactly one argument, got: $*"
        exit 1
    fi
    extension=$1
    shift
    package=$(find . -name *Rcheck -type d)
    if [[ ${#package[@]} -ne 1 ]]; then
        echo "Could not find package Rcheck directory, skipping log dump."
        exit 0
    fi
    for name in $(find "${package}" -type f -name "*${extension}"); do
        echo ">>> Filename: ${name} <<<"
        cat ${name}
    done
}

DumpLogs() {
    echo "Dumping test execution logs."
    DumpLogsByExtension "out"
    DumpLogsByExtension "log"
    DumpLogsByExtension "fail"
    }

RunTests() {
    echo "Building with: R CMD build ${R_BUILD_ARGS}"
    R CMD build ${R_BUILD_ARGS} .
    FILE=$(ls -1 *.tar.gz)
    echo "Testing with: R CMD check \"${FILE}\" ${R_CHECK_ARGS}"
    R CMD check "${FILE}" ${R_CHECK_ARGS}
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
    "dump_logs")
        DumpLogs
        ;;
    "dump_logs_by_extension")
        DumpLogsByExtension "$*"
        ;;
esac
