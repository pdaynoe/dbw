#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @requirements: base-devel, dmenu
# @description : uses dmenu to search or browse the www
#                if no searchterm is supplied it may use a "bookmark"
#                this is inspired by qutebrowser quickmark und quick search eingines
######################################################################

# ### define searchengine if no key is specified
# ### f.e.: gg:google/dg:duckduckgo/sx:searx
# ### all these searchengines need to be defined in the database
# DEFKEY=dg


# ### find dmenu or rofi command or error out
# function get_drun() {
#     if [ -z $(command -v rofi) ]; then
#        DMENURUN="$(command -v rofi)" -show -mode
#     elif [ -z $(command -v dmenu) ]; then
#        DMENURUN=${DMENURUN:-dmenu}
#     else
#        printf "\nNo dmenu/rofi command found\!\n" ; exit 1
#     fi
# }

# ### find dmenu command or error out
# [ -z "$(command -v dmenu)" ] || printf "\nNo dmenu/rofi command found\!\n" ; exit 1


# ### found this on WWW, unable to find and refere to source
# ### it encodes urls
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

function get_dbfile() {
      # ### find suitable database file if unset
      DBFILE="${DBFILE:-${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db}"
      [ -f "$DBFILE" ] || printf "\nNo dmenu command found\!\n"
}

function get_input() {

      # ### use  awk & dmenu on supplied input, defines variable INPUT

      INPUT=$(awk '{if(/#/){}else{printf ("%s\t-\t%s\n", $1, $2) }}' "$DBFILE" | dmenu -i -p "Search/Browse ")
      [[ $INPUT == *Cancel* ]] && unset INPUT SEARCHTERM SEARCHKEY URL &&  exit 0
      [ -z "$INPUT" ] && unset INPUT SEARCHTERM SEARCHKEY URL &&  exit 0


      SEARCHKEY="$(echo "$INPUT" | awk '{print $1}')"
      SEARCHTERM="$(echo "$INPUT" | awk '{$1=""; print $0}' | awk '{$1=$1};1')"

      # ### this is failsafe for if you tab through suggestions
      # ### searchterm is unset because of the '-' (dash)
      # ### bookmark is opend instead of searchterm
      # ### no, you can't search for terms with a dash
      [[ "$INPUT" == *-*  ]] && SEARCHTERM=""

      DBENTRY="$(awk '{if(/#/){}else{print $0}}' "$DBFILE" | grep "$SEARCHKEY")"
      # ### failsafe: if DBENTRYS has more than 1 line
      [ "$(echo "$DBENTRY" | wc -l)" -ge 2 ] && DBENTRY="$(echo "$DBENTRY" | head -1)"
      [ -z "$DBENTRY" ] && SEARCHTERM=$INPUT && SEARCHKEY=${DEFKEY:-dg}
}


function get_goto() {
      # ### use grep & awk on $SEARCH-variables to find URL
      # ### TODO: find way to only use awk, as this decreases requirements

      # ### handle no key in database entry
      # ### if no key found, and no default searchengine is set
      # ### then duckduckgo is used as default engine
      # ### qutebrwoser automatically uses a default search engine
      # ### this is for all the other browsers out there!
      # if [ -n "$DBENTRY" ]; then
      #      DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s", $2,$3) }}' )";
      #      [ -n "$SEARCHTERM" ] && eval "$(printf "%s" GOTO="$DOMAIN"/"$(urlencode "$SEARCHTERM")")"
      #      # [ -n "$SEARCHTERM" ] && GT="$DOMAIN$(echo "$DBENTRY" | awk '{print $5}')";
      #      # eval "$(echo GOTO="$DOMAIN"/"$(urlencode "$SEARCHTERM")")"
      # # elif [ -z "$DEFSEARCHENGINE" ]; then
      # #      SEARCHKEY=dg;
      # #      DOMAIN="$(grep "$SEARCHKEY" "$DBFILE" | awk '{if(/#/){}else{printf ("https://%s.%s", $2, $3) }}')"
      # else
      #      DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s", $2,$3) }}' )";
      #      [ -n "$SEARCHTERM" ] && eval "$(printf "%s" GOTO="$DOMAIN"/"$(urlencode "$SEARCHTERM")")"
      #      # GOTO="$(urlencode "$SEARCHTERM")"
      # fi





      # DBENTRY="$(awk '{if(/#/){}else{print $0}}' "$DBFILE" | grep "$SEARCHKEY")"
      # [ -z "$DBENTRY" ] && SEARCHTERM=$INPUT && SEARCHKEY=${DEFKEY:-dg}

      if [ -z "$SEARCHTERM" ]; then
            BMARK="$(echo "$DBENTRY" | awk '{print $4}')"
            [[ "$BMARK" == *-*  ]] && DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s", $2,$3) }}' )" \
                  || DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$4) }}' )";
            GOTO="$DOMAIN"

      elif [ -n "$SEARCHTERM" ] ; then
            DOMAIN="$(echo "$DBENTRY" | awk '{if(/#/){}else{printf ("https://%s.%s%s", $2,$3,$5) }}' )";
            SEARCHTERM=$(urlencode "$SEARCHTERM")
            eval "$(printf "%s" GT="$DOMAIN")"
            SEARCHEND=$(echo "$DBENTRY" | awk '{print $6}')
            [[ "$SEARCHEND" == *-* ]] && SEARCHEND=""
            GOTO="$GT$SEARCHEND"
      # else
      fi

      # [ -n "$SEARCHTERM" ] && SEARCHTERM="$(urlencode "$SEARCHTERM")" ; eval "$(printf "%s" GOTO="$DOMAIN")"
      # GOTO="$GT$SEARCHEND"

      # DOMAIN="$(grep "$SEARCHKEY" "$DBFILE" | awk '{if(/#/){}else{printf ("https://%s.%s/", $2, $3) }}')"
      # DOMAIN="$(grep $SEARCHKEY $DBFILE) | awk  '{print $2}'.$(grep $SEARCHKEY $DBFILE) | awk  '{print $3}'"

      # declare URL=$(urlencode $INPUT)
      # # $BROWSER "https://duckduckgo.com/?q=$URL"
      # $BROWSER "https://duckduckgo.com/?q=$URL&kai=1&kaf=1&kaa=bd93f9&k9=50fa7b&kx=f1fa8c&k8=f8f8f2&ka=p&k7=282a36&km=l&ko=s&kae=t&ku=-1&kw=n&kj=282a36&ks=m&kt=p&ky=44475a&kf=1q%3D%3Fk7%3D282a36%26k8%3Df8f8f2%26&t=h_&ia=web"

      # ### defines GOTO variable, depending on input/databse/database entrys
      # GOTO="$URL"
}

# ### this is the way
# [ -z "$DMENURUN" ] && get_drun;
# [ -z "$DBFILE" ] && get_dbfile;
# [ -z "$INPUT"  ] && get_input; # this uses dmenu

# ### this is the way
# [ -z "$DMENURUN" ] && get_drun;
[ -z "$DBFILE" ] && get_dbfile;
[ -z "$INPUT"  ] && get_input; # this uses dmenu

get_goto;

# ### this is the actual run!
BROWSER=${BROWSER:-xdg-open}
"$BROWSER" "$GOTO"
