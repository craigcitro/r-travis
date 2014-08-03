# R+Travis

[![Build Status](https://travis-ci.org/craigcitro/r-travis.svg?branch=master,osx)](https://travis-ci.org/craigcitro/r-travis)

This package has a simple shell script for use in running R package builds on
[travis](http://travis-ci.org/), along with a sample `.travis.yml` file. One
should be able to set up travis for their own project by:
* Copying `sample.travis.yml` to `.travis.yml` in your project.
  * Copying `sample_revdeps.travis.yml` to `.travis.yml` in your project will passively check reverse dependencies.
* Adding `.travis.yml` to your `.Rbuildignore`.
* Modifying `.travis.yml` to list any packages that must be installed from
  github (instead of CRAN).
* [Turn on travis](https://travis-ci.org/profile) for your project. (Note that
  in some cases, it may take time for travis to start watching your repo.)
* Add a
  [travis "build status" shield](http://about.travis-ci.org/docs/user/status-images/)
  to your `README` file.

See the [wiki](https://github.com/craigcitro/r-travis/wiki) for more
extensive documentation and examples.

## Linux or OS X builds

By default, builds are done on Linux. That is enabled by choosing
`language: c` in the .travis.yml file. Builds on OS X can be enabled by
choosing `language: objective-c`. See the comments in `sample.travis.yml`.

Currently, Travis-CI does not support builds that loop over platforms (such as
Linux and OS X) in one build.

## The future

My plan is to ultimately merge this into travis as a first-class citizen, so
that the simplest config would simply say `language: R`. However, I'm using
this repo as a staging ground to make sure I have the kinks worked out first.
The end goal would be for the `.travis.yml` for an R project to be something
as simple as

    language: r
    github_packages:
      - assertthat
      - devtools
