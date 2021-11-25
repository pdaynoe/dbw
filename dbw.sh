#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @requirements: base-devel, dmenu
# @description : uses dmenu to search or browse the www
#                if no searchterm is supplied it may use a "bookmark"
#                this is inspired by qutebrowser quickmark und quick search eingines
######################################################################


DEFKEY=dg
# BROWSER=librewolf

# ### find dmenu command or error out
[ -n "$(command -v dmenu)" ] || printf "\nNo dmenu command found\!\n" || exit 1


# ### found this on WWW, unable to find and refere to source
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
      DBFILE="${DBFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db}"
      [ -f "$DBFILE" ] || printf "\nNo database found\!\n" || exit 1
}

get_input() {
      # ### use awk & dmenu on supplied input, defines variable INPUT
      INPUT=$(awk '{if(/#/){}else{printf ("%s\t\t-\t%s\n", $1, $2) }}' "$DBFILE" | dmenu -i -p "Search/Browse ")
      [[ "$INPUT" == *Cancel* ]] && unset INPUT SEARCHTERM SEARCHKEY && exit 0

      # ### open url immediately if it contains http(s) or www
      [[ "$INPUT" == *http* ]] && goto_www
      [[ "$INPUT" == *www*  ]] && goto_www

      [ -z "$INPUT" ] && unset INPUT SEARCHTERM SEARCHKEY &&  exit 0

      SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
      SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

      # ### this is failsafe for if you tab through suggestions
      # ### searchterm is unset because of the '-' (dash)
      # ### bookmark is opened instead of searchterm
      # ### simply said: no, you can't search for terms with a dash
      [[ "$INPUT" == *-* ]] && SEARCHTERM=""

      DBENTRY="$(awk '{if(/#/){}else{print $0}}' "$DBFILE" | grep "^$SEARCHKEY ")"
      # ### failsafe: if DBENTRYS has more than 1 line
      [ "$(echo "$DBENTRY" | wc -l)" -ge 2 ] && DBENTRY="$(echo "$DBENTRY" | head -1)"
      [ -z "$DBENTRY" ] && SEARCHTERM=$INPUT && SEARCHKEY=${DEFKEY:-dg} && DBENTRY="$(awk '{if(/#/){}else{print $0}}' "$DBFILE" | grep "^$SEARCHKEY ")"

}

goto_www(){
      BROWSER=${BROWSER:-xdg-open}
      "$BROWSER" "$INPUT" && unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO && exit 0
}


goto_bmark() {
            BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
            # [ "$BMARK" = '-' ] && DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s", $2,$3) }}' )" \
            [ "$BMARK" = '-' ] && DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s", $2,$3) }}' )" \
                  || DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$4) }}' )";
            GOTO="$DOMAIN"
}


full_search() {
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )";
            SEARCHTERM=$(urlencode "$SEARCHTERM")
            eval "$(printf "%s" GT="$DOMAIN")"
            SEARCHEND=$(echo "$DBENTRY" | awk '{print $6}')
            [ "$SEARCHEND" = '-' ] && SEARCHEND=""
            GOTO="$GT$SEARCHEND"
}



run() {
      # ### the actual run function
      BROWSER=${BROWSER:-xdg-open}
      "$BROWSER" "$GOTO" && unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO && exit 0
}



# ### main
[ -z "$DBFILE" ] && get_dbfile;

get_input; # this uses dmenu
if [ -z "$SEARCHTERM" ]; then
      # [ "$SEARCHKEY" = "$DEFKEY" ] && full_search ; run
      goto_bmark
      run

elif [ -n "$SEARCHTERM" ] ; then
      full_search
      run
fi

