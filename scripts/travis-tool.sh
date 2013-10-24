#!/bin/bash
# Bootstrap an R/travis environment.

set -e

Bootstrap() {
  OS=$(uname -s)
  if [ "Darwin" == "${OS}" ]; then
    BootstrapMac
  elif [ "Linux" == "${OS}" ]; then
    BootstrapLinux
  else
    echo "Unknown OS: ${OS}"
    exit 1
  fi
  
  # Install devtools & bootstrap to github version
  sudo R --slave --vanilla -e 'install.packages(c("devtools"), repos=c("http://cran.rstudio.com"))'
  sudo R --slave --vanilla -e 'library(devtools); install_github("devtools")'
}

BootstrapLinux() {
  # Update first.
  sudo apt-get update -qq

  # TODO(craigcitro): Add this back behind a flag.
  # Install tex.
  # sudo apt-get install texlive-full texlive-fonts-extra

  # Set up our CRAN mirror.
  sudo add-apt-repository "deb http://cran.rstudio.com/bin/linux/ubuntu precise/"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
  sudo apt-get update -qq

  # Install R.
  sudo apt-get install r-base r-base-dev
}

BootstrapMac() {
  # TODO(craigcitro): Figure out TeX in OSX+travis.

  # Install R.
  brew install r
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
  sudo R --slave --vanilla -e "library(devtools); install_github(\"${PACKAGE_NAME}\"${ARGS})"
}

InstallDeps() {
  sudo R --slave --vanilla -e 'library(devtools); options(repos = c(CRAN = "http://cran.rstudio.com")); devtools:::install_deps(dependencies = TRUE)'
}

RunTests() {
  sudo R CMD build --no-build-vignettes .
  FILE=$(ls -1 *.tar.gz)
  sudo R CMD check "${FILE}" --no-manual
  exit $?
}

COMMAND=$1
echo "Running command ${COMMAND}"
shift
case $COMMAND in
  "bootstrap")
    Bootstrap
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
