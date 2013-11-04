#!/bin/bash

set -e

BRANCH=$(git branch | egrep "^\*" | sed -r 's/^\* //')
OSX_BRANCH=${BRANCH}-osx

if test -n "$(git status --porcelain)"; then
  echo "$(basename $0): Working copy not clean. Exiting."
  exit 1
fi

git checkout $OSX_BRANCH
git merge $BRANCH --no-edit
git checkout $BRANCH
