#!/usr/bin/env bash
######################################################################
# @author      : pdaynoe
# @description : simple install script for dbw
######################################################################

# Check if the script exists
if [ ! -f "$PWD/dbw.sh" ]; then
    echo "Error: No dbw.sh file found in current directory"
    exit 1
fi

# Install to /usr/bin
if [ -d /usr/bin ]; then
    echo "Installing dbw to /usr/bin..."
    sudo cp "$PWD/dbw.sh" /usr/bin/dbw
    sudo chmod +x /usr/bin/dbw
else
    echo "Warning: /usr/bin not found. Installing to ~/bin if it exists..."
    if [ -d "$HOME/bin" ]; then
        cp "$PWD/dbw.sh" "$HOME/bin/dbw"
        chmod +x "$HOME/bin/dbw"
    else
        echo "Warning: Neither /usr/bin nor ~/bin found. Please install manually."
        exit 1
    fi
fi

# Copy database if it doesn't exist
DB_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/dbwdb.db"
if [ ! -f "$DB_PATH" ]; then
    echo "Creating database file at $DB_PATH..."
    mkdir -p "$(dirname "$DB_PATH")"
    cp "$PWD/example_database.db" "$DB_PATH"
fi

echo "Installation complete!"
echo "You can now run 'dbw' from anywhere."
