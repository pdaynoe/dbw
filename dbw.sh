#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @requirements: base-devel, dmenu
# @description : uses dmenu to search or browse the www
#                if no searchterm is supplied it may use a "bookmark"
#                this is inspired by qutebrowser quickmark und quick search eingines
######################################################################
# ### other DEFKEY may be used to set different default searchengine
# DEFKEY=dg
DEFKEY=sx
### sx key is now defaulting to localhost, other searxng instances need to have a different key.
# BROWSER=librewolf
# BROWSER=xdg-open

# ### find dmenu command or error out
# DMENU=rofi
DMENU="wofi --show dmenu"
# [ -n "$(command -v $DMENU)" ] || printf "\nNo $DMENU command found\!\n" || exit 1

# ### found this on WWW, unable to find source
# ### it encodes strings into urls format
urlencode(){
  local str="$*"
  local encoded=""
  local i c x
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
    # Find suitable database file if DBFILE is unset
    export DBFILE="${DBFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db}"
    [ -f "$DBFILE" ] || { printf "\nError: No database found\n" >&2; exit 1; }
}

get_input() {
    # Use awk & dmenu on supplied input, defines variable INPUT
    INPUT=$(awk '{if(/#/){}else{printf ("%s\t\t-\t%s\n", $1, $2) }}' "$DBFILE" | $DMENU -i -p "Search/Browse")
    
    # Handle cancel or empty input
    [[ "$INPUT" == *Cancel* ]] && { unset INPUT SEARCHTERM SEARCHKEY; exit 0; }
    [ -z "$INPUT" ] && { unset INPUT SEARCHTERM SEARCHKEY; exit 0; }

    # Open url immediately if it contains http(s) or www
    [[ "$INPUT" == *http* ]] || [[ "$INPUT" == *www* ]] && goto_www

    SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
    SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

    # This is failsafe for if you tab through suggestions
    [[ "$INPUT" == *$(printf '\t')* ]] && SEARCHTERM=""

    DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    
    # Perform defaultkey search for nonexisting searchkey
    if [ -z "$DBENTRY" ]; then
        SEARCHTERM=$INPUT
        SEARCHKEY=${DEFKEY:-dg}
        DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    fi
}

goto_www(){
    BROWSER=${BROWSER:-xdg-open}
    "$BROWSER" "$INPUT" & unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO & exit 0
}


goto_bmark() {
    local BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
    
    if [ "$BMARK" = '-' ]; then
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s", $2,$3) }}' )"
    else
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s%s", $2,$3,$4) }}' )"
    fi
    
    # Special handling for searxng instances
    [[ "$SEARCHKEY" = 'sx' ]] && DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s", $2) }}' )"
    
    GOTO="$DOMAIN"
}


full_search() {
            [[ "$SEARCHKEY" = 'sx' ]] && { DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s%s", $2,$5) }}' )"; } \
                                      || { DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )"; }
            SEARCHTERM=$(urlencode "$SEARCHTERM")
            SEARCHEND=$(echo "$DBENTRY" | awk '{print $6}')
            [[ "$SEARCHEND" = '-' ]] && SEARCHEND=""
            # Properly substitute $SEARCHTERM in the URL
            GOTO="${DOMAIN/\$SEARCHTERM/$SEARCHTERM}$SEARCHEND"
            # Fallback in case substitution didn't work
            [[ "$GOTO" == *"\$SEARCHTERM"* ]] && GOTO="${DOMAIN/\$SEARCHTERM/$SEARCHTERM}$SEARCHEND"
}


run() {
    # ### the actual run function
    BROWSER=${BROWSER:-xdg-open}
    "$BROWSER" "$GOTO" && unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO && exit 0
}

# Main execution
main() {
    [ -z "$DBFILE" ] && get_dbfile
    
    get_input  # this uses dmenu/rofi
    
    if [ -z "$SEARCHTERM" ]; then
        goto_bmark
        run
    else
        full_search
        run
    fi
}

# Execute main function
main

