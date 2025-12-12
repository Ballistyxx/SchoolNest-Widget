# SchoolNest Period Widget

A lightweight Quickshell widget that displays your current school period and time remaining. Shows transitions between classes and provides a hover popup with the full day schedule.

## Features

- Displays current period and countdown timer
- Shows transition times between periods
- Hover to view complete schedule
- Auto-fetches schedule daily from schoolnest.org
- Minimal resource usage

## Requirements

- Quickshell (with ii theme)
- curl, grep, sed
- systemd (for automatic updates)

## Installation

### Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/Ballistyxx/SchoolNest-Widget/main/install.sh | bash
```

Then follow the post-installation instructions to add the widget to your bar.

### Manual Installation

1. Install the schedule fetcher:

```bash
mkdir -p ~/.local/bin
cp fetch_schedule.sh ~/.local/bin/
chmod +x ~/.local/bin/fetch_schedule.sh
```

2. Set up automatic updates:

```bash
mkdir -p ~/.config/systemd/user
cp schoolnest-schedule.{service,timer} ~/.config/systemd/user/
systemctl --user enable --now schoolnest-schedule.timer
```

3. Install widget files:

```bash
cp PeriodWidget_themed.qml ~/.config/quickshell/ii/modules/ii/bar/PeriodWidget.qml
cp PeriodWidgetPopup.qml ~/.config/quickshell/ii/modules/ii/bar/
```

4. Fetch initial schedule:

```bash
~/.local/bin/fetch_schedule.sh
```

5. Add to your bar by editing `~/.config/quickshell/ii/modules/ii/bar/BarContent.qml`:

Insert after the workspaces section (around line 150):

```qml
BarGroup {
    id: periodWidgetGroup
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: periodWidget.isSchoolHours ? 110 : 0
    visible: Config.options.bar.verbose
    clip: true

    Behavior on implicitWidth {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    PeriodWidget {
        id: periodWidget
        Layout.alignment: Qt.AlignVCenter
        Layout.fillWidth: true
    }
}

VerticalBarSeparator {
    visible: Config.options?.bar.borderless && Config.options.bar.verbose && periodWidget.isSchoolHours
}
```

6. Reload quickshell.

## Display Format

- During class: `2:47/PD3` (2:47 remaining in Period 3)
- Between classes: `4:32/TRNS` (4:32 until next period)
- Lunch: `15:00/LNCH`

Hover over the widget to see the complete daily schedule with the current period highlighted.

## Configuration

Schedule updates run daily and on boot. Check status:

```bash
systemctl --user status schoolnest-schedule.timer
```

Manual schedule update:

```bash
~/.local/bin/fetch_schedule.sh
```

## Uninstall

```bash
systemctl --user stop schoolnest-schedule.timer
systemctl --user disable schoolnest-schedule.timer
rm ~/.config/systemd/user/schoolnest-schedule.{service,timer}
rm ~/.local/bin/fetch_schedule.sh
rm ~/.config/quickshell/ii/modules/ii/bar/PeriodWidget*.qml
rm -rf ~/.local/share/schoolnest
```

Remove the widget code from `BarContent.qml` and reload quickshell.

## License

MIT
