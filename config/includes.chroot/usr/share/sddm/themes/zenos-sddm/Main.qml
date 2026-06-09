import QtQuick 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#0a2832"
    
    anchors.fill: parent
    
    TextConstants {
        id: textConstants
    }
    
    Rectangle {
        x: 0
        y: 0
        width: parent.width
        height: parent.height
        
        Image {
            source: "background.png"
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            smooth: true
        }
    }
    
    ColumnLayout {
        anchors.centerIn: parent
        
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 400
            height: 320
            color: "transparent"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 16
                
                Text {
                    text: "ZEN-OS"
                    font.pixelSize: 48
                    font.bold: true
                    color: "#00b0b0"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "Game. Build. Create."
                    font.pixelSize: 16
                    color: "#809090"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Item { height: 20 }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    
                    Text {
                        text: textConstants.userName
                        color: "#a0c0c0"
                        font.pixelSize: 14
                    }
                    
                    TextBox {
                        id: username
                        Layout.fillWidth: true
                        height: 40
                        color: "#1a3040"
                        borderColor: "#008080"
                        textColor: "#ffffff"
                        font.pixelSize: 16
                        text: userModel.lastUser
                        focus: !password.activeFocus
                        
                        KeyNavigation.backtab: shutdownButton
                        KeyNavigation.tab: password
                        
                        onTextChanged: {
                            if (text !== "") {
                                password.focus = true
                            }
                        }
                    }
                    
                    Text {
                        text: textConstants.password
                        color: "#a0c0c0"
                        font.pixelSize: 14
                    }
                    
                    PasswordBox {
                        id: password
                        Layout.fillWidth: true
                        height: 40
                        color: "#1a3040"
                        borderColor: "#008080"
                        textColor: "#ffffff"
                        font.pixelSize: 16
                        focus: username.text !== ""
                        
                        KeyNavigation.backtab: username
                        KeyNavigation.tab: loginButton
                        
                        onTextChanged: {
                        }
                        
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(username.text, password.text, session.index)
                                event.accepted = true
                            }
                        }
                    }
                }
                
                Item { height: 8 }
                
                RowLayout {
                    Layout.fillWidth: true
                    
                    ComboBox {
                        id: session
                        Layout.fillWidth: true
                        height: 36
                        color: "#1a3040"
                        borderColor: "#008080"
                        textColor: "#ffffff"
                        model: sessionModel
                        index: sessionModel.lastIndex
                        
                        KeyNavigation.backtab: password
                        KeyNavigation.tab: loginButton
                    }
                    
                    Button {
                        id: loginButton
                        text: textConstants.login
                        height: 36
                        width: 100
                        color: "#008080"
                        borderColor: "#00b0b0"
                        textColor: "#ffffff"
                        
                        onClicked: sddm.login(username.text, password.text, session.index)
                        
                        KeyNavigation.backtab: session
                        KeyNavigation.tab: shutdownButton
                    }
                }
            }
        }
    }
    
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        spacing: 10
        
        Button {
            id: shutdownButton
            text: textConstants.shutdown
            height: 30
            color: "transparent"
            borderColor: "#006060"
            textColor: "#809090"
            
            onClicked: sddm.powerOff()
            
            KeyNavigation.backtab: loginButton
            KeyNavigation.tab: rebootButton
        }
        
        Button {
            id: rebootButton
            text: textConstants.reboot
            height: 30
            color: "transparent"
            borderColor: "#006060"
            textColor: "#809090"
            
            onClicked: sddm.reboot()
            
            KeyNavigation.backtab: shutdownButton
            KeyNavigation.tab: username
        }
    }
    
    Component.onCompleted: {
        if (username.text === "") {
            username.focus = true
        } else {
            password.focus = true
        }
    }
}
