#!/bin/sh

: "${HOME:?ERROR: \$HOME is not set}"

DEST="$HOME/.local/share/man/man99"

mkdir -p "$DEST"

if command -v rsync >/dev/null 2>&1; then
    rsync -au "./man99/" "$DEST"/
else
    echo "rsync not found"
    exit 1
fi

mandb "$HOME/.local/share/man"
echo "Kick'N'Vim manpages installed to $DEST"

