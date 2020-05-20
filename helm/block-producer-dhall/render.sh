#!/bin/sh
set -e
BASEDIR="$(dirname "$0")"
export INPUT="$(yaml-to-dhall --records-loose "$BASEDIR/dhall/Input/Main.dhall" <&0)"
exec dhall-to-yaml --documents --quoted --file "$BASEDIR/dhall/Template.dhall"
