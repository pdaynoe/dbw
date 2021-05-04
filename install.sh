[[ -f $PWD/dbwww ]] || echo "Error: No dbwww file found"; exit

[[ -d /usr/local/bin ]] && sudo cp $PWD/dbwww /usr/local/bin
[[ -d /usr/bin ]]       && sudo cp $PWD/dbwww /usr/bin

cp  ${XDG_CONFIG_HOME:?$HOME/.config}
