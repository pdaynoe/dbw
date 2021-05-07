# dbw
## This Readme needs further reworking ###
# Description:
## Fullname:Dmenu-Database-for-Bookmark-and-Searchengines-WWW-Wrapper-Wrench
### short: ddbbswww ### 
### even shorter: dbw ### 

A dmenu script using a unified database-like file to either use bookmarks or search the _www_\.
This script uses a database file as a bookmark or searchengine lookup for your browser.
If no database.db file exist in $XDG_CONFIG_HOME, the example-databse will be copied to mentioned location if using the installation script
 
# Dependencies:
dmenu, bash, gawk (other versions might work too - not tested!), grep

# Installation
A small installation.sh script exists. It uses /usr/bin instead of /usr/local/bin.
Please check the script before launching it, and edit it to your needs.
Or just clone and copy or symlink the file into a $PATH folder.

