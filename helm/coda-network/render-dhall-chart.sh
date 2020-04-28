#!/bin/sh
set -e
BASEDIR="$(dirname "$0")"
export INPUT="$(yaml-to-dhall --records-loose "($BASEDIR/dhall/schema.dhall).Type" <&0)"
exec dhall-to-yaml --quoted --file "$BASEDIR/dhall/coda-network.dhall"
