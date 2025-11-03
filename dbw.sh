#!/usr/bin/env sh
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
urlencode() {
    str="$1"
    encoded=""
    i=0
    str_len=$(expr length "$str")
    while [ "$i" -lt "$str_len" ]; do
        c=$(expr substr "$str" $((i + 1)) 1)
        case "$c" in
            [a-zA-Z0-9._~-] ) x="$c" ;;
            ' ' ) x='%20' ;;
            * ) 
                # Use printf with proper quoting for POSIX compatibility
                x=$(printf '%%%.2x' "'$c")
                ;;
        esac
        encoded="$encoded$x"
        i=$((i + 1))
    done
    echo "$encoded"
}

# Get database file
get_dbfile() {
    # Find suitable database file if DBFILE is unset
    if [ -z "$DBFILE" ]; then
        DBFILE="${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db"
    fi
    if [ ! -f "$DBFILE" ]; then
        printf "\nError: No database found at %s\n" "$DBFILE" >&2
        exit 1
    fi
}

# Get user input
get_input() {
    # Use awk & dmenu on supplied input, defines variable INPUT
    INPUT="$(awk '{if(/#/){}else{printf ("%s\t\t-\t%s\n", $1, $2) }}' "$DBFILE" | $DMENU -i -p "Search/Browse")"
    
    # Handle cancel or empty input
    case "$INPUT" in
        *Cancel*)
            unset INPUT SEARCHTERM SEARCHKEY
            exit 0
            ;;
        "")
            unset INPUT SEARCHTERM SEARCHKEY
            exit 0
            ;;
    esac

    # Open url immediately if it contains http(s) or www
    case "$INPUT" in
        *http*)
            goto_www
            ;;
        *www*)
            goto_www
            ;;
    esac

    # Parse input
    SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
    SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

    # This is failsafe for if you tab through suggestions
    case "$INPUT" in
        *$(printf '\t')*)
            SEARCHTERM=""
            ;;
    esac

    # Look up the database entry
    DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    
    # Perform defaultkey search for nonexisting searchkey
    if [ -z "$DBENTRY" ]; then
        SEARCHTERM="$INPUT"
        SEARCHKEY="${DEFKEY:-dg}"
        DBENTRY="$(grep -m 1 -e "^$SEARCHKEY " "$DBFILE")"
    fi
    
    # Validate that we found a valid entry
    if [ -z "$DBENTRY" ]; then
        printf "\nError: Could not find entry for key '%s'\n" "$SEARCHKEY" >&2
        exit 1
    fi
}

# Open URL directly
goto_www() {
    BROWSER="${BROWSER:-xdg-open}"
    "$BROWSER" "$INPUT"
    unset SEARCHKEY SEARCHTERM SEARCHEND DBENTRY DOMAIN GOTO
    exit 0
}

# Handle bookmark access
goto_bmark() {
    BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
    
    if [ "$BMARK" = "-" ]; then
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s", $2,$3) }}' )"
    else
        DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s.%s%s", $2,$3,$4) }}' )"
    fi
    
    # Special handling for searxng instances
    case "$SEARCHKEY" in
        sx)
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s", $2) }}' )"
            ;;
    esac
    
    GOTO="$DOMAIN"
}

# Process full search - implement proper $SEARCHTERM replacement
full_search() {
    # Determine domain based on search key
    case "$SEARCHKEY" in
        sx)
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("http://%s%s", $2,$5) }}' )"
            ;;
        *)
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )"
            ;;
    esac
    
    # Encode search term
    SEARCHTERM="$(urlencode "$SEARCHTERM")"
    
    # Get search end part
    SEARCHEND="$(echo "$DBENTRY" | awk '{print $6}')"
    
    # Handle empty search end
    if [ "$SEARCHEND" = "-" ]; then
        SEARCHEND=""
    fi
    
    # Properly substitute $SEARCHTERM in the URL using POSIX-compatible method
    # Since POSIX doesn't support advanced string substitution, we'll use sed
    # Check if the domain contains literal $SEARCHTERM pattern
    if echo "$DOMAIN" | grep -q "\\\\$SEARCHTERM"; then
        # Use sed to replace literal $SEARCHTERM with actual search term
        GOTO="$(echo "$DOMAIN" | sed "s/\\\\\$SEARCHTERM/$SEARCHTERM/g")$SEARCHEND"
    elif echo "$DOMAIN" | grep -q '\$SEARCHTERM'; then
        # Use sed to replace literal $SEARCHTERM with actual search term
        GOTO="$(echo "$DOMAIN" | sed "s/\$SEARCHTERM/$SEARCHTERM/g")$SEARCHEND"
    else
        # No special replacement needed, just concatenate
        GOTO="$DOMAIN$SEARCHEND"
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
    BROWSER="${BROWSER:-xdg-open}"
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

