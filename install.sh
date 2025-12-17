#!/usr/bin/env bash
# Seasoning installation script
set -euo pipefail

PREFIX="${PREFIX:-/usr}"
SHARE_DIR="$PREFIX/share/seasoning"

echo "Installing Seasoning..."

# Install main script
echo "→ Installing seasoning to $PREFIX/bin/"
sudo install -Dm755 seasoning.sh "$PREFIX/bin/seasoning"

# Install ticker
echo "→ Installing seasoning-ticker to $PREFIX/bin/"
sudo install -Dm755 seasoning-ticker.sh "$PREFIX/bin/seasoning-ticker"

# Install plugins
echo "→ Installing plugins to $SHARE_DIR/plugins/"
sudo mkdir -p "$SHARE_DIR/plugins"
sudo install -Dm755 plugins/* "$SHARE_DIR/plugins/"

# Install default settings
echo "→ Installing default settings to $SHARE_DIR/"
sudo install -Dm644 settings.json "$SHARE_DIR/settings.json"

# Install systemd service
echo "→ Installing systemd user service"
mkdir -p ~/.config/systemd/user/
install -Dm644 seasoning-ticker.service ~/.config/systemd/user/

# Reload systemd
systemctl --user daemon-reload

echo ""
echo "✓ Installation complete!"
echo ""
echo "Next steps:"
echo "  1. Add Seasoning modules to your Waybar config"
echo "     See: docs/waybar-config.jsonc"
echo ""
echo "  2. Enable and start the ticker:"
echo "     systemctl --user enable --now seasoning-ticker"
echo ""
echo "  3. Customize settings (optional):"
echo "     mkdir -p ~/.config/seasoning"
echo "     cp $SHARE_DIR/settings.json ~/.config/seasoning/"
echo "     nano ~/.config/seasoning/settings.json"
echo ""
echo "  4. Restart Waybar"
echo "     pkill waybar"