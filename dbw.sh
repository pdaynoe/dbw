#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @requirements: base-devel, dmenu
# @description : uses dmenu to search or browse the www
#                if no searchterm is supplied it may use a "bookmark"
#                this is inspired by qutebrowser quickmark und quick search eingines
######################################################################
# ### duckduckgo is implemented as default searchengine
# ### other DEFKEY may be used to set different default searchengine
# DEFKEY=bv
# BROWSER=librewolf

# ### find dmenu command or error out
[ -n "$(command -v dmenu)" ] || printf "\nNo dmenu command found\!\n" || exit 1


# ### found this on WWW, unable to find source
# ### it encodes strings into urls format
urlencode(){
  declare str="$*"
  declare encoded=""
  declare i c x
  for ((i=0; i<${#str}; i++ )); do
    c=${str:$i:1}
    case "$c" in
      [-_.~a-zA-Z0-9] ) x="$c" ;;
      * ) printf -v x '%%%02x' "'$c";;
    esac
    encoded+="$x"
  done
  echo "$encoded"
}


get_dbfile() {
      # ### find suitable database file if DBFILE is unset
      export DBFILE="${DBFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db}"
      [ -f "$DBFILE" ] || printf "\nNo database found\!\n" || exit 1
}

get_input() {
      # ### use awk & dmenu on supplied input, defines variable INPUT
      INPUT=$(awk '{if(/#/){}else{printf ("%s\t\t-\t%s\n", $1, $2) }}' "$DBFILE" | dmenu -i -p "Search/Browse")
      [[ "$INPUT" == *Cancel* ]] && unset INPUT SEARCHTERM SEARCHKEY && exit 0
      [ -z "$INPUT" ] && unset INPUT SEARCHTERM SEARCHKEY && exit 0

      # ### open url immediately if it contains http(s) or www
      [[ "$INPUT" == *http* ]] || [[ "$INPUT" == *www*  ]] && goto_www

      SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
      SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

      # ### this is failsafe for if you tab through suggestions
      [[ "$INPUT" == *$(printf '\t')* ]] && SEARCHTERM=""

      DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
      # ### perform defaultkey search for nonexisting searchkey
      [ -z "$DBENTRY" ] && SEARCHTERM=$INPUT SEARCHKEY=${DEFKEY:-dg}\
          DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
}

goto_www(){
      BROWSER=${BROWSER:-xdg-open}
      "$BROWSER" "$INPUT" & unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO & exit 0
}


goto_bmark() {
            BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
            [ "$BMARK" = '-' ] && DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s", $2,$3) }}' )" \
                  || DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$4) }}' )";
            GOTO="$DOMAIN"
}


full_search() {
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )";
            SEARCHTERM=$(urlencode "$SEARCHTERM")
            eval "$(printf "%s" GT="$DOMAIN")"
            SEARCHEND=$(echo "$DBENTRY" | awk '{print $6}')
            [[ "$SEARCHEND" = '-' ]] && SEARCHEND=""
            GOTO="$GT$SEARCHEND"
}


run() {
      # ### the actual run function
      BROWSER=${BROWSER:-xdg-open}
      "$BROWSER" "$GOTO" && unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO && exit 0
}


# ### main
[ -z "$DBFILE" ] && get_dbfile;

get_input; # this uses dmenu/rofi

if [ -z "$SEARCHTERM" ]; then
      goto_bmark
      run
  else
      full_search
      run
fi

# [ -z "$SEARCHTERM" ] && goto_bmark|| goto_bmark; run


# if [ -z "$SEARCHTERM" ]; then
#       goto_bmark
#       run

# elif [ -n "$SEARCHTERM" ] ; then
#       full_search
#       run
# fi

