#!/usr/bin/env sh

######################################################################
# @author      : pday
# @file        : install-dbwww.sh
#
# @description : install file for installing the dbwww and
#                copying exmaple database-cfg file to $XDG_CONFIG_HOME (default: ~/.config)
######################################################################


[[ -f $PWD/dbwww ]] || echo "Error: No dbwww file found"; exit

[[ -d /usr/local/bin ]] && sudo cp $PWD/dbwww /usr/local/bin
[[ -d /usr/bin ]]       && sudo cp $PWD/dbwww /usr/bin

cp  ${XDG_CONFIG_HOME:?$HOME/.config}
