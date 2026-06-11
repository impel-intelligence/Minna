#!/bin/sh
set -eu # Fail on errors and unset variables

# Produces tmp/apps/iris.tar.xz from the notarized Iris.app (used by Sparkle).
cd tmp/apps/
tar --no-xattrs -cJf iris.tar.xz Iris.app
