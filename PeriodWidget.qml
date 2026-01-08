// School Period Widget for Quickshell II Bar
// Displays current period and time remaining in format: "2:47/PD4"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    // Fill the parent container (which has a fixed width)
    // Hide widget when no valid schedule or outside school hours
    implicitWidth: (isScheduleValid && isSchoolHours) ? (parent ? parent.width : 80) : 0
    implicitHeight: (isScheduleValid && isSchoolHours) ? rowLayout.implicitHeight : 0
    visible: isScheduleValid && isSchoolHours

    // Path to the schedule JSON file
    property string scheduleFile: Quickshell.env("HOME") + "/.local/share/schoolnest/schedule.json"
    property string reloadTriggerFile: Quickshell.env("HOME") + "/.local/share/schoolnest/.reload_trigger"
    property var scheduleData: null
    property string currentPeriodName: ""
    property int timeRemaining: 0 // in seconds
    property bool isSchoolHours: false
    property bool scheduleLoaded: false
    property bool isTransition: false  // True when between periods
    property bool isScheduleValid: false  // True if schedule is from today and has data
    property string lastTriggerModTime: ""  // Track last modification time

    // Check for reload trigger file changes
    Timer {
        running: true
        repeat: true
        interval: 5000  // Check every 5 seconds
        triggeredOnStart: true
        onTriggered: checkReloadTrigger()
    }

    // Process to check trigger file modification time
    Process {
        id: triggerChecker
        command: ["stat", "-c", "%Y", root.reloadTriggerFile]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const modTime = data.trim()
                if (root.lastTriggerModTime !== "" && modTime !== root.lastTriggerModTime) {
                    console.log("Reload trigger detected, reloading schedule...")
                    loadSchedule()
                }
                root.lastTriggerModTime = modTime
            }
        }

        onExited: (code, status) => {
            // Trigger file doesn't exist yet - create it
            if (code !== 0 && root.lastTriggerModTime === "") {
                root.lastTriggerModTime = "0"
            }
        }
    }

    function checkReloadTrigger() {
        triggerChecker.running = true
    }

    // Process to read the schedule file
    Process {
        id: scheduleReader
        command: ["cat", root.scheduleFile]
        running: false

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.scheduleData = JSON.parse(data)
                    root.scheduleLoaded = true

                    // Check if schedule is valid (from today and has data)
                    const today = new Date()
                    const todayStr = today.getFullYear() + "-" +
                                   String(today.getMonth() + 1).padStart(2, '0') + "-" +
                                   String(today.getDate()).padStart(2, '0')

                    const fetchedDate = root.scheduleData.fetched_date || ""
                    const hasSchedule = root.scheduleData.schedule !== null &&
                                      root.scheduleData.schedule !== undefined

                    root.isScheduleValid = (fetchedDate === todayStr) && hasSchedule

                    if (!root.isScheduleValid) {
                        console.log("Schedule invalid - Date:", fetchedDate, "Today:", todayStr, "Has schedule:", hasSchedule)
                    } else {
                        console.log("Schedule loaded successfully for", fetchedDate)
                    }
                } catch (e) {
                    console.error("Failed to parse schedule:", e)
                    root.isScheduleValid = false
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                console.warn("Failed to read schedule file:", root.scheduleFile)
            }
        }
    }

    // Timer to update every second
    Timer {
        running: true
        repeat: true
        interval: 1000
        triggeredOnStart: true
        onTriggered: updateCurrentPeriod()
    }

    // Timer to reload schedule once per hour
    Timer {
        running: true
        repeat: true
        interval: 3600000 // 1 hour
        triggeredOnStart: true
        onTriggered: loadSchedule()
    }

    function loadSchedule() {
        scheduleReader.running = true
    }

    function updateCurrentPeriod() {
        if (!root.isScheduleValid || !root.scheduleData || !root.scheduleData.schedule || !root.scheduleData.schedule.periods) {
            root.isSchoolHours = false
            root.isTransition = false
            return
        }

        const now = new Date()
        const currentSeconds = now.getHours() * 3600 + now.getMinutes() * 60 + now.getSeconds()
        const periods = root.scheduleData.schedule.periods

        // Check if we're in a period
        for (let i = 0; i < periods.length; i++) {
            const period = periods[i]
            if (currentSeconds >= period.start_time && currentSeconds < period.end_time) {
                const remaining = period.end_time - currentSeconds
                root.timeRemaining = remaining
                root.currentPeriodName = getPeriodAbbreviation(period.p_n)
                root.isSchoolHours = true
                root.isTransition = false
                return
            }
        }

        // Check if we're in a transition between periods
        for (let i = 0; i < periods.length - 1; i++) {
            const currentPeriod = periods[i]
            const nextPeriod = periods[i + 1]

            if (currentSeconds >= currentPeriod.end_time && currentSeconds < nextPeriod.start_time) {
                const remaining = nextPeriod.start_time - currentSeconds
                root.timeRemaining = remaining
                root.currentPeriodName = "TRNS"
                root.isSchoolHours = true
                root.isTransition = true
                return
            }
        }

        // Check if we're before the first period
        if (currentSeconds < periods[0].start_time) {
            const remaining = periods[0].start_time - currentSeconds
            root.timeRemaining = remaining
            root.currentPeriodName = "TRNS"
            root.isSchoolHours = true
            root.isTransition = true
            return
        }

        root.isSchoolHours = false
        root.isTransition = false
    }

    function getPeriodAbbreviation(periodName) {
        // Convert "Period 3" to "PD3", "Lunch" to "LNCH", etc.
        if (periodName.startsWith("Period ")) {
            return "PD" + periodName.substring(7)
        } else if (periodName === "Lunch") {
            return "LNCH"
        } else if (periodName === "Study Hall") {
            return "STDY"
        }
        return periodName.substring(0, 4).toUpperCase()
    }

    function formatTimeRemaining(seconds) {
        const minutes = Math.floor(seconds / 60)
        const secs = seconds % 60
        return minutes + ":" + (secs < 10 ? "0" : "") + secs
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: ""
        }

        StyledText {
            id: periodText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            // Force text update by binding to both properties directly
            text: formatTimeRemaining(root.timeRemaining) + "/" + root.currentPeriodName
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        PeriodWidgetPopup {
            hoverTarget: mouseArea
            scheduleData: root.scheduleData
            currentPeriodName: root.currentPeriodName
            isSchoolHours: root.isSchoolHours
            isTransition: root.isTransition
        }
    }
}
