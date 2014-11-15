#!/bin/bash

set -e

BRANCH=$(git symbolic-ref HEAD | awk -F/ '{print $3}')
OSX_BRANCH=${OSX_BRANCH:-${BRANCH}-osx}

if test -n "$(git status --porcelain)"; then
  echo "$(basename $0): Working copy not clean. Exiting."
  exit 1
fi

if [[ -n "$(git branch | egrep "^ *$OSX_BRANCH")" ]]; then
    git checkout $OSX_BRANCH
    if git merge $BRANCH --no-edit; then
        git checkout $BRANCH
        exit 0
    fi
    echo "WARNING: Can't merge, falling back to overwriting branch"
    git checkout $BRANCH
    git branch -D $OSX_BRANCH
fi

git checkout -b $OSX_BRANCH
sed -i '' -e 's/^language: c/language: objective-c/' .travis.yml
git add .travis.yml
git commit -m "change language to objective-c to test OS X"
git checkout $BRANCH
