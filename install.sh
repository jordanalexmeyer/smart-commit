#!/bin/bash

# Create bin directory in user's home if it doesn't exist
INSTALL_DIR="$HOME/bin"
mkdir -p "$INSTALL_DIR"

# Copy the scripts to the install directory
cp "$(dirname "$0")/smart-commit.sh" "$INSTALL_DIR/git-smart-commit.sh"
chmod +x "$INSTALL_DIR/git-smart-commit.sh"

cp "$(dirname "$0")/smart-branch.sh" "$INSTALL_DIR/git-smart-branch.sh"
chmod +x "$INSTALL_DIR/git-smart-branch.sh"

# Create git aliases
git config --global alias.sc '!~/bin/git-smart-commit.sh'
git config --global alias.sb '!~/bin/git-smart-branch.sh'

echo "Installation complete!"
echo "You can now use:"
echo "  'git sc' to run smart commit"
echo "  'git sb' to run smart branch"
