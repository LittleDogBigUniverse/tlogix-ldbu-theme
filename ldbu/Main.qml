
/*
 *   Copyright 2014 David Edmundson <davidedmundson@kde.org>
 *
 *   This program is free software; you can redistribute it and/or modify
 *   it under the terms of the GNU Library General Public License as
 *   published by the Free Software Foundation; either version 2 or
 *   (at your option) any later version.
 *
 *   This program is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details
 *
 *   You should have received a copy of the GNU Library General Public
 *   License along with this program; if not, write to the
 *   Free Software Foundation, Inc.,
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
import QtQuick 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.1 as Controls

import SddmComponents 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import SddmComponents 2.0

import "./components"

Image {
    id: root
    width: 1000
    height: 1000

    TextConstants {
        id: textConstants
    }

    Repeater {
        model: screenModel
        Background {
            x: geometry.x
            y: geometry.y
            width: geometry.width
            height: geometry.height
            property real ratio: geometry.width / geometry.height
            source: {
                if (ratio == 16.0 / 9.0) {
                    source = "./components/artwork/background_169.png"
                } else if (ratio == 16.0 / 10.0) {
                    source = "./components/artwork/background_1610.png"
                } else if (ratio == 4.0 / 3.0) {
                    source = "./components/artwork/background_43.png"
                } else {
                    source = "./components/artwork/background.png"
                }
            }
            fillMode: Image.PreserveAspectFit
            onStatusChanged: {
                if (status == Image.Error
                        && source != config.defaultBackground) {
                    source = config.defaultBackground
                }
            }
        }
    }

    property bool debug: false

    Rectangle {
        id: debug3
        color: "green"
        visible: debug
        width: 3
        height: parent.height
        anchors.horizontalCenter: root.horizontalCenter
    }

    Controls.StackView {
        id: stackView
        property variant geometry: screenModel.geometry(screenModel.primary)
        width: geometry.width
        height: geometry.height / 20
        anchors.bottom: parent.bottom

        initialItem: BreezeBlock {
            id: loginPrompt
            width: parent.width
            main: {

            }

            controls: Item {
                height: childrenRect.height
                width: parent.width

                property alias username: userInput.text
                property alias password: passwordInput.text
                property alias sessionIndex: sessionCombo.index

                ColumnLayout {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 0
                    RowLayout {
                        height: root.height / 30
                        //NOTE password is deliberately the first child so it gets focus
                        //be careful when re-ordering
                        anchors.fill: parent

                        TextBox {
                            id: userInput
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.width * 0.1
                            text: userModel.lastUser
                            font.pixelSize: root.height / 80
                            KeyNavigation.backtab: rebootButton
                            KeyNavigation.tab: passwordInput
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return
                                        || event.key === Qt.Key_Enter) {
                                    sddm.login(username, password, sessionIndex)
                                    event.accepted = true
                                }
                            }
                        }

                        PasswordBox {
                            id: passwordInput
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.width * 0.1
                            font.pixelSize: root.height / 80
                            tooltipBG: "lightgrey"
                            focus: true
                            Timer {
                                interval: 200
                                running: true
                                onTriggered: passwordInput.forceActiveFocus()
                            }
                            KeyNavigation.backtab: userInput
                            KeyNavigation.tab: loginButton
                            Keys.onPressed: {
                                if (event.key === Qt.Key_Return
                                        || event.key === Qt.Key_Enter) {
                                    sddm.login(username, password, sessionIndex)
                                    event.accepted = true
                                }
                            }
                        }

                        Button {
                            id: loginButton
                            text: textConstants.login
                            Layout.fillHeight: true
                            Layout.preferredWidth: root.width * 0.1
                            font.pixelSize: root.height / 80
                            color: "#F7931E"
                            onClicked: sddm.login(username, password,
                                                  sessionIndex)
                            KeyNavigation.tab: shutdownButton
                        }
                    }
                }

                ComboBox {
                    anchors.left: parent.left
                    id: sessionCombo
                    width: parent.width * 0.1
                    height: root.height / 30
                    font.pixelSize: root.height / 80
                    arrowIcon: "angle-down.png"
                    model: sessionModel
                    index: sessionModel.lastIndex

                    KeyNavigation.backtab: loginButton
                }

                Button {
                    id: shutdownButton
                    text: textConstants.shutdown
                    anchors.right: parent.right
                    width: parent.width * 0.05
                    height: root.height / 30
                    font.pixelSize: root.height / 80
                    color: "#F7931E"
                    onClicked: sddm.powerOff()
                    KeyNavigation.backtab: loginButton
                    KeyNavigation.tab: rebootButton
                }

                Button {
                    id: rebootButton
                    text: textConstants.reboot
                    anchors.right: parent.right
                    width: parent.width * 0.05
                    anchors.rightMargin: parent.width * 0.05 + 10
                    height: root.height / 30
                    font.pixelSize: root.height / 80
                    color: "#F7931E"
                    onClicked: sddm.reboot()

                    KeyNavigation.backtab: shutdownButton
                    KeyNavigation.tab: userInput
                }

                Connections {
                    target: sddm
                    onLoginFailed: {
                        passwordInput.enabled = true
                        passwordInput.selectAll()
                        passwordInput.forceActiveFocus()
                    }
                }
            }

            function startLogin() {
                sddm.login(username, password, sessionIndex)
            }

            Component {
                id: logoutScreenComponent
                LogoutScreen {
                    onCancel: {
                        stackView.pop()
                    }

                    onShutdownRequested: {
                        sddm.powerOff()
                    }

                    onRebootRequested: {
                        sddm.reboot()
                    }
                }
            }
        }
    }
}
