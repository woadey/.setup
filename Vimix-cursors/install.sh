#!/bin/bash

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

ROOT_UID=0
DEST_DIR=

# Destination directory
if [ "$UID" -eq "$ROOT_UID" ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="$HOME/.local/share/icons"
fi

if [ -d "$DEST_DIR/Vimix-cursors" ]; then
  rm -rf "$DEST_DIR/Vimix-cursors"
fi

if [ -d "$DEST_DIR/Vimix-white-cursors" ]; then
  rm -rf "$DEST_DIR/Vimix-white-cursors"
fi

cp -r $SCRIPT_DIR/dist/ $DEST_DIR/Vimix-cursors
cp -r $SCRIPT_DIR/dist-white/ $DEST_DIR/Vimix-white-cursors

echo "Finished..."

