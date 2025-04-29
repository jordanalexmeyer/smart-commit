#!/bin/bash

# Create bin directory in user's home if it doesn't exist
INSTALL_DIR="$HOME/bin"
mkdir -p "$INSTALL_DIR"

# Copy the script to the install directory
cp "$(dirname "$0")/smart-commit.sh" "$INSTALL_DIR/git-smart-commit.sh"
chmod +x "$INSTALL_DIR/git-smart-commit.sh"

# Create git alias
git config --global alias.sc '!~/bin/git-smart-commit.sh'

echo "Installation complete! You can now use 'git sc' to run smart commit."
