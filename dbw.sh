#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @requirements: base-devel, dmenu
# @description : uses dmenu to search or browse the www
#                if no searchterm is supplied it may use a "bookmark"
#                this is inspired by qutebrowser quickmark und quick search eingines
######################################################################

# Configuration
DEFKEY=sx
### sx key is now defaulting to localhost, other searxng instances need to have a different key.
# BROWSER=librewolf
# BROWSER=xdg-open

# Menu configuration
DMENU="wofi --show dmenu"

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

# Get database file
get_dbfile() {
    # Find suitable database file if DBFILE is unset
    export DBFILE="${DBFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db}"
    if [ ! -f "$DBFILE" ]; then
        printf "\nError: No database found at %s\n" "$DBFILE" >&2
        exit 1
    fi
}

# Get user input
get_input() {
    # Use awk & dmenu on supplied input, defines variable INPUT
    INPUT=$(awk '{if(/#/){}else{printf ("%s\t\t-\t%s\n", $1, $2) }}' "$DBFILE" | $DMENU -i -p "Search/Browse")
    
    # Handle cancel or empty input
    if [[ "$INPUT" == *Cancel* ]] || [ -z "$INPUT" ]; then
        unset INPUT SEARCHTERM SEARCHKEY
        exit 0
    fi

    # Open url immediately if it contains http(s) or www
    if [[ "$INPUT" == *http* ]] || [[ "$INPUT" == *www* ]]; then
        goto_www
    fi

    # Parse input
    SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
    SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

    # This is failsafe for if you tab through suggestions
    if [[ "$INPUT" == *$(printf '\t')* ]]; then
        SEARCHTERM=""
    fi

    # Look up the database entry
    DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    
    # Perform defaultkey search for nonexisting searchkey
    if [ -z "$DBENTRY" ]; then
        SEARCHTERM=$INPUT
        SEARCHKEY=${DEFKEY:-dg}
        DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    fi
    
    # Validate that we found a valid entry
    if [ -z "$DBENTRY" ]; then
        printf "\nError: Could not find entry for key '%s'\n" "$SEARCHKEY" >&2
        exit 1
    fi
}

# Open URL directly
goto_www(){
    BROWSER=${BROWSER:-xdg-open}
    "$BROWSER" "$INPUT" & 
    unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO 
    exit 0
}

# Handle bookmark access
goto_bmark() {
    local BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
    
    if [ "$BMARK" = '-' ]; then
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s", $2,$3) }}' )"
    else
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s%s", $2,$3,$4) }}' )"
    fi
    
    # Special handling for searxng instances
    if [[ "$SEARCHKEY" = 'sx' ]]; then
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s", $2) }}' )"
    fi
    
    GOTO="$DOMAIN"
}

# Process full search
full_search() {
    # Determine domain based on search key
    if [[ "$SEARCHKEY" = 'sx' ]]; then
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s%s", $2,$5) }}' )"
    else
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )"
    fi
    
    # Encode search term
    SEARCHTERM=$(urlencode "$SEARCHTERM")
    
    # Get search end part
    SEARCHEND=$(echo "$DBENTRY" | awk '{print $6}')
    
    # Handle empty search end
    if [[ "$SEARCHEND" = '-' ]]; then
        SEARCHEND=""
    fi
    
    # Properly substitute $SEARCHTERM in the URL
    GOTO="${DOMAIN/\$SEARCHTERM/$SEARCHTERM}$SEARCHEND"
    
    # Fallback in case substitution didn't work
    if [[ "$GOTO" == *"\$SEARCHTERM"* ]]; then
        GOTO="${DOMAIN/\$SEARCHTERM/$SEARCHTERM}$SEARCHEND"
    fi
}

# Execute the action
run() {
    # Check if we have a valid GOTO URL
    if [ -z "$GOTO" ]; then
        printf "\nError: No URL to open\n" >&2
        exit 1
    fi
    
    # Open in browser
    BROWSER=${BROWSER:-xdg-open}
    "$BROWSER" "$GOTO" 
    unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO 
    exit 0
}

# Main execution
main() {
    # Initialize database file
    if [ -z "$DBFILE" ]; then
        get_dbfile
    fi
    
    # Get user input
    get_input  # this uses dmenu/rofi
    
    # Process based on whether there's a search term
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

