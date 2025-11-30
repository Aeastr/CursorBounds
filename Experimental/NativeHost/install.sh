#!/bin/bash
#
# Install CursorBounds Native Messaging Host
#
# Usage: ./install.sh <extension_id>
#

set -e

EXTENSION_ID="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$EXTENSION_ID" ]; then
    echo "Usage: $0 <extension_id>"
    echo ""
    echo "To get your extension ID:"
    echo "1. Load the extension in Chrome (chrome://extensions)"
    echo "2. Enable Developer mode"
    echo "3. Copy the ID shown under the extension"
    exit 1
fi

echo "Installing CursorBounds Native Messaging Host..."
echo "Extension ID: $EXTENSION_ID"

# Compile the Swift host
echo "Compiling native host..."
swiftc -O "$SCRIPT_DIR/CursorBoundsHost.swift" -o /usr/local/bin/CursorBoundsHost

if [ $? -ne 0 ]; then
    echo "Failed to compile native host"
    exit 1
fi

chmod +x /usr/local/bin/CursorBoundsHost
echo "Installed: /usr/local/bin/CursorBoundsHost"

# Create the manifest with the extension ID
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
mkdir -p "$MANIFEST_DIR"

cat > "$MANIFEST_DIR/com.cursorbounds.helper.json" << EOF
{
  "name": "com.cursorbounds.helper",
  "description": "CursorBounds Native Messaging Host",
  "path": "/usr/local/bin/CursorBoundsHost",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
EOF

echo "Installed manifest: $MANIFEST_DIR/com.cursorbounds.helper.json"

# Also install for Chromium-based browsers
BROWSERS=(
    "$HOME/Library/Application Support/Chromium/NativeMessagingHosts"
    "$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"
    "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/NativeMessagingHosts"
    "$HOME/Library/Application Support/Vivaldi/NativeMessagingHosts"
    "$HOME/Library/Application Support/Arc/User Data/NativeMessagingHosts"
)

for dir in "${BROWSERS[@]}"; do
    if [ -d "$(dirname "$dir")" ]; then
        mkdir -p "$dir"
        cp "$MANIFEST_DIR/com.cursorbounds.helper.json" "$dir/"
        echo "Installed for: $(basename "$(dirname "$dir")")"
    fi
done

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Load the Chrome extension from: $SCRIPT_DIR/../ChromeExtension"
echo "2. Restart Chrome/browser"
echo "3. The extension will automatically track cursor positions"
