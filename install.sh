#!/bin/bash
set -e

QUICKSHELL_BAR_DIR="$HOME/.config/quickshell/ii/modules/ii/bar"
LOCAL_BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

echo "Installing SchoolNest Period Widget for Quickshell..."

# Create directories
mkdir -p "$LOCAL_BIN_DIR"
mkdir -p "$SYSTEMD_USER_DIR"
mkdir -p "$QUICKSHELL_BAR_DIR"

# Install fetch script
echo "Installing schedule fetcher..."
cp fetch_schedule.sh "$LOCAL_BIN_DIR/"
chmod +x "$LOCAL_BIN_DIR/fetch_schedule.sh"

# Install systemd services
echo "Installing systemd services..."
cp schoolnest-schedule.service "$SYSTEMD_USER_DIR/"
cp schoolnest-schedule.timer "$SYSTEMD_USER_DIR/"

# Install widget files
echo "Installing widget components..."
cp PeriodWidget_themed.qml "$QUICKSHELL_BAR_DIR/PeriodWidget.qml"
cp PeriodWidgetPopup.qml "$QUICKSHELL_BAR_DIR/"

# Enable and start timer
echo "Enabling automatic schedule updates..."
systemctl --user daemon-reload
systemctl --user enable --now schoolnest-schedule.timer

# Fetch initial schedule
echo "Fetching initial schedule..."
"$LOCAL_BIN_DIR/fetch_schedule.sh"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Add the widget to your bar by editing:"
echo "   ~/.config/quickshell/ii/modules/ii/bar/BarContent.qml"
echo ""
echo "2. Add this code after the workspaces section (around line 150):"
echo ""
echo "   BarGroup {"
echo "       id: periodWidgetGroup"
echo "       anchors.verticalCenter: parent.verticalCenter"
echo "       implicitWidth: periodWidget.isSchoolHours ? 110 : 0"
echo "       visible: Config.options.bar.verbose"
echo "       clip: true"
echo ""
echo "       Behavior on implicitWidth {"
echo "           NumberAnimation {"
echo "               duration: 200"
echo "               easing.type: Easing.InOutQuad"
echo "           }"
echo "       }"
echo ""
echo "       PeriodWidget {"
echo "           id: periodWidget"
echo "           Layout.alignment: Qt.AlignVCenter"
echo "           Layout.fillWidth: true"
echo "       }"
echo "   }"
echo ""
echo "   VerticalBarSeparator {"
echo "       visible: Config.options?.bar.borderless && Config.options.bar.verbose && periodWidget.isSchoolHours"
echo "   }"
echo ""
echo "3. Reload quickshell"
echo ""
echo "Schedule updates daily at boot. Check status with:"
echo "  systemctl --user status schoolnest-schedule.timer"
