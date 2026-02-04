#!/bin/bash
# Direct plugin installer for development/testing
# Usage: ./install-plugins.sh

XMAKE_DIR="$HOME/.xmake"
SRC_DIR="$(dirname "$0")"

echo "Installing plugins from: $SRC_DIR"

# Plugins
for plugin in flash debugger emulator serve deploy; do
    dest="$XMAKE_DIR/plugins/$plugin"
    mkdir -p "$dest"
    cp -v "$SRC_DIR/plugins/$plugin/"*.lua "$dest/" 2>/dev/null || true
    
    # Copy subdirectories (backends, database, etc.)
    for subdir in backends database; do
        if [ -d "$SRC_DIR/plugins/$plugin/$subdir" ]; then
            mkdir -p "$dest/$subdir"
            cp -v "$SRC_DIR/plugins/$plugin/$subdir/"* "$dest/$subdir/" 2>/dev/null || true
        fi
    done
done

# Utils modules
mkdir -p "$XMAKE_DIR/modules/utils"
cp -v "$SRC_DIR/utils/"*.lua "$XMAKE_DIR/modules/utils/" 2>/dev/null || true

# Rules
for rule in embedded embedded.vscode embedded.test host.test; do
    src_rule=$(echo "$rule" | tr '.' '/')
    if [ -d "$SRC_DIR/rules/$src_rule" ]; then
        dest="$XMAKE_DIR/rules/$rule"
        mkdir -p "$dest"
        cp -v "$SRC_DIR/rules/$src_rule/"*.lua "$dest/" 2>/dev/null || true
        
        # Copy database if exists
        if [ -d "$SRC_DIR/rules/$src_rule/database" ]; then
            mkdir -p "$dest/database"
            cp -v "$SRC_DIR/rules/$src_rule/database/"* "$dest/database/" 2>/dev/null || true
        fi
        
        # Copy linker if exists
        if [ -d "$SRC_DIR/rules/$src_rule/linker" ]; then
            mkdir -p "$dest/linker"
            cp -v "$SRC_DIR/rules/$src_rule/linker/"* "$dest/linker/" 2>/dev/null || true
        fi
    fi
done

echo ""
echo "Done. Plugins installed to: $XMAKE_DIR"
