/*
 * ZEN-OS KSplash Theme
 * Dark background with pulsating teal logo + loading indicator
 */
import QtQuick 2.15

Item {
    id: root

    property real progress: 0

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#0a1620"
    }

    // Subtle gradient overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#00121500" }
            GradientStop { position: 0.6; color: "#000a1520" }
            GradientStop { position: 1.0; color: "#00102025" }
        }
    }

    // Logo text
    Text {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -60
        text: "ZEN-OS"
        font.pixelSize: Math.min(root.width, root.height) * 0.08
        font.bold: true
        font.family: "DejaVu Sans"
        color: "#00b0b0"

        // Pulsating animation
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.6
                to: 1.0
                duration: 1500
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 1.0
                to: 0.6
                duration: 1500
                easing.type: Easing.InOutSine
            }
        }
    }

    // Tagline
    Text {
        anchors.top: logo.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 10
        text: "Game. Build. Create."
        font.pixelSize: Math.min(root.width, root.height) * 0.018
        font.family: "DejaVu Sans"
        color: "#809090"
        opacity: 0.7
    }

    // Progress bar background
    Rectangle {
        id: progressBg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.min(root.height * 0.12, 80)
        width: Math.min(root.width * 0.4, 400)
        height: 4
        radius: 2
        color: "#1a2a35"
    }

    // Progress bar fill
    Rectangle {
        anchors.left: progressBg.left
        anchors.verticalCenter: progressBg.verticalCenter
        width: progressBg.width * root.progress
        height: progressBg.height
        radius: 2
        color: "#00b0b0"

        Behavior on width {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }
    }

    // Loading dots
    Row {
        anchors.top: progressBg.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 15
        spacing: 6

        Repeater {
            model: 3
            Rectangle {
                width: 5
                height: 5
                radius: 2.5
                color: "#00b0b0"
                opacity: 0.3

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 400 }
                    NumberAnimation { from: 0.3; to: 1.0; duration: 400 }
                    NumberAnimation { from: 1.0; to: 0.3; duration: 400 }
                }
            }
        }
    }

    // Connections from KSplash engine
    Connections {
        target: ksplash
        function onProgressChanged(p) {
            root.progress = p
        }
    }
}
