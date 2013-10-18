# R+Travis

[![Build Status](https://travis-ci.org/craigcitro/r-travis.png)](https://travis-ci.org/craigcitro/r-travis)


This package has a simple shell script for use in running R package builds on
[travis](http://travis-ci.org/), along with a sample `.travis.yml` file. One
should be able to set up travis for their own project by:
* Copying `sample.travis.yml` to `.travis.yml` in your project.
* Modifying `.travis.yml` to list any packages that must be installed from
  github (instead of CRAN).
* [Turn on travis](https://travis-ci.org/profile) for your project.
* Add a [travis shield](http://about.travis-ci.org/docs/user/status-images/)
  to your `README` file.

## The future

My plan is to ultimately merge this into travis as a first-class citizen, so
that the simplest config would simply say `language: R`. However, I'm using
this repo as a staging ground to make sure I have the kinks worked out first.
