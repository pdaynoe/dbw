# dbw
## Use at own risk! ###
# Description:
## Fullname:Dmenu-Database-for-Bookmark-and-Searchengines-Web-Wrapper-Wrench
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

# Usage:
Type in your search query for a direct search with duckduckgo or type in a bang to use one of the bookmarks or search engines of the database.
For database entries including a bookmark and a search engine, using no search term will open the bookmark.
If an entry has no search engine it will only open the bookmark even with an emitted search term.
