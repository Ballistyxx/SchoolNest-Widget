import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

StyledPopup {
    id: root

    // These properties are set from the parent PeriodWidget
    property var scheduleData: null
    property string currentPeriodName: ""
    property bool isSchoolHours: false
    property bool isTransition: false

    function formatTime(seconds) {
        const hours = Math.floor(seconds / 3600)
        const minutes = Math.floor((seconds % 3600) / 60)
        const period = hours >= 12 ? "PM" : "AM"
        const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours
        return displayHours + ":" + (minutes < 10 ? "0" : "") + minutes + " " + period
    }

    function getPeriodAbbreviation(periodName) {
        if (periodName.startsWith("Period ")) {
            return "PD" + periodName.substring(7)
        } else if (periodName === "Lunch") {
            return "LNCH"
        } else if (periodName === "Study Hall") {
            return "STDY"
        }
        return periodName.substring(0, 4).toUpperCase()
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 8

        StyledPopupHeaderRow {
            icon: "schedule"
            label: root.scheduleData?.schedule?.schedule_name ?? "Schedule"
        }

        // Show all periods
        Column {
            spacing: 2
            Layout.fillWidth: true

            Repeater {
                model: root.scheduleData?.schedule?.periods ?? []

                Rectangle {
                    width: periodRow.implicitWidth + 16
                    height: periodRow.implicitHeight + 8
                    radius: Appearance.rounding.small
                    color: {
                        const periodAbbrev = getPeriodAbbreviation(modelData.p_n)
                        // Highlight current period (won't match "TRNS" during transitions)
                        if (root.isSchoolHours && periodAbbrev === root.currentPeriodName) {
                            return Appearance.colors.colPrimaryContainer
                        }
                        return "transparent"
                    }

                    RowLayout {
                        id: periodRow
                        anchors.centerIn: parent
                        spacing: 12

                        StyledText {
                            Layout.preferredWidth: 80
                            horizontalAlignment: Text.AlignLeft
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: {
                                const periodAbbrev = getPeriodAbbreviation(modelData.p_n)
                                return (root.isSchoolHours && periodAbbrev === root.currentPeriodName)
                                    ? Font.Bold
                                    : Font.Normal
                            }
                            color: {
                                const periodAbbrev = getPeriodAbbreviation(modelData.p_n)
                                if (root.isSchoolHours && periodAbbrev === root.currentPeriodName) {
                                    return Appearance.colors.colOnPrimaryContainer
                                }
                                return Appearance.colors.colOnSurfaceVariant
                            }
                            text: modelData.p_n
                        }

                        StyledText {
                            Layout.preferredWidth: 120
                            horizontalAlignment: Text.AlignRight
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: {
                                const periodAbbrev = getPeriodAbbreviation(modelData.p_n)
                                return (root.isSchoolHours && periodAbbrev === root.currentPeriodName)
                                    ? Font.Bold
                                    : Font.Normal
                            }
                            color: {
                                const periodAbbrev = getPeriodAbbreviation(modelData.p_n)
                                if (root.isSchoolHours && periodAbbrev === root.currentPeriodName) {
                                    return Appearance.colors.colOnPrimaryContainer
                                }
                                return Appearance.colors.colOnSurfaceVariant
                            }
                            text: formatTime(modelData.start_time) + " - " + formatTime(modelData.end_time)
                        }
                    }
                }
            }
        }
    }
}
