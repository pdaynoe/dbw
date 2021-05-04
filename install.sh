#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @description : simple install script for dbw
######################################################################


[ -f "$PWD"/dbw ] || echo "Error: No dbw file found"; exit 1

# [ -d /usr/local/bin ] && sudo cp "$PWD"/dbw /usr/local/bin
[ -d /usr/bin ]   && sudo cp "$PWD"/dbw.sh /usr/bin/dbw

[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db"  ] ||  cp "$PWD"/example_database.db  "${XDG_CONFIG_HOME:-$HOME/.config}"
