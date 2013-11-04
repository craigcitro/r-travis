#!/bin/bash

set -e

BRANCH=$(git branch | egrep "^\*" | sed -r 's/^\* //')
OSX_BRANCH=${BRANCH}-osx

test -z $(git status --porcelain)

git checkout -b $OSX_BRANCH
sed -i -r 's/^language: c/language: objective-c/' .travis.yml
git add .travis.yml
git commit -m "change language to objective-c to test OS X"
git checkout $BRANCH
