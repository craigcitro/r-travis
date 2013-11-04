#!/bin/bash

set -e

BRANCH=$(git branch | egrep "^\*" | sed -r 's/^\* //')
OSX_BRANCH=${BRANCH}-osx

test -z $(git status --porcelain)

git checkout $OSX_BRANCH
git merge $BRANCH --no-edit
git checkout $BRANCH
