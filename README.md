# dbw
## Use at own risk! ###
# Description:
## Fullname:Dmenu-Database-for-Bookmark-and-Searchengines-Web-Wrapper-Wrench
### short: ddbbswww ### 
### even shorter: dbw ### 

A dmenu script using a unified database-like file to either use bookmarks or search the _www_.
This script uses a database file as a bookmark or searchengine lookup for your browser.
If no database.db file exist in $XDG_CONFIG_HOME, the example-database will be copied to mentioned location if using the installation script
 
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

# Database Format:
The database file follows this format (columns separated by whitespace):
```
# key  name  domain.ending  bookmark  search-url   end-of-search-url
dg          duckduckgo                   com      -              /?q=$SEARCHTERM                       -
gg          google                       com      -              /search?q=$SEARCHTERM                 -
gh          github                       com      -              /search?q=$SEARCHTERM                 -
```

Column meanings:
1. **Key**: Short identifier (like "dg" for duckduckgo) - used in searches
2. **Name**: Display name for the search engine/bookmark
3. **Domain ending**: TLD (com, org, etc.) for constructing URLs
4. **Bookmark**: Optional bookmark path (use "-" if no bookmark)
5. **Search URL**: URL template with $SEARCHTERM placeholder for search queries
6. **End of search URL**: Additional URL parameters to append to search results

# Examples:
- `dg just a test` → searches DuckDuckGo for "just a test"
- `gh openhands` → searches GitHub for "openhands" 
- `wp` → opens Wikipedia homepage (no search term)
- `fb` → opens Facebook homepage (no search term)

# Improvements Made:
- Added proper error handling and validation
- Improved input parsing and validation
- Better database file checking
- Enhanced error messages
- More robust installation script
- Fixed potential issues with variable substitution
- Added explicit exit statements for cleaner execution
- Fully POSIX compliant (works with dash, ash, etc.)
- Corrected URL encoding for special characters
- Fixed $SEARCHTERM variable replacement
