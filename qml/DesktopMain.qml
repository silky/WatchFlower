/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2018 Emeric Grange - All Rights Reserved
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * \date      2018
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.0

ApplicationWindow {
    id: applicationWindow
    color: "#E0FAE7"
    visible: true

    width: 720
    height: 480
    minimumWidth: 720
    minimumHeight: 480

    flags: Qt.Window | Qt.MaximizeUsingFullscreenGeometryHint

    DesktopGeometrySaver {
        window: applicationWindow
        windowName: "applicationWindow"
    }

    // Events handling /////////////////////////////////////////////////////////

    Connections {
        target: header
        onBackButtonClicked: {
            if (content.state !== "DeviceList") {
                content.state = "DeviceList"
            }
        }
        onRefreshButtonClicked: {
            deviceManager.refreshDevices()
        }
        onRescanButtonClicked: {
            deviceManager.scanDevices()
        }
        onSettingsButtonClicked: content.state = "Settings"
        onExitButtonClicked: settingsManager.exit()
    }
    Connections {
        target: content
        onStateChanged: {
            if (content.state === "DeviceList") {
                header.leftIcon.source = "qrc:/assets/watchflower.svg"
            } else {
                header.leftIcon.source = "qrc:/assets/menu_back.svg"
            }
        }
    }
    Connections {
        target: systrayManager
        onSettingsClicked: {
            content.state = "Settings"
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.ForwardButton
        onClicked: {
            if (mouse.button === Qt.BackButton) {
                content.state = "DeviceList"
            } else if (mouse.button === Qt.ForwardButton) {
                if (curentlySelectedDevice)
                    content.state = "DeviceDetails"
            }
        }
    }
    Shortcut {
        sequence: StandardKey.Back
        onActivated: {
            content.state = "DeviceList"
        }
    }
    Shortcut {
        sequence: StandardKey.Forward
        onActivated: {
            if (curentlySelectedDevice)
                content.state = "DeviceDetails"
        }
    }
    Item {
        focus: true
        Keys.onBackPressed: {
            if (Qt.platform.os === "android" || Qt.platform.os === "ios") {
                if (content.state === "DeviceList") {
                    // hide windows?
                } else {
                    content.state = "DeviceList"
                }
            } else {
                content.state = "DeviceList"
            }
        }
    }
    onClosing: {
        if (Qt.platform.os === "android" || Qt.platform.os === "ios") {
            close.accepted = false;
        } else {
            close.accepted = false;
            applicationWindow.hide()
        }
    }

    // QML /////////////////////////////////////////////////////////////////////

    property var curentlySelectedDevice

    DesktopHeader {
        id: header
        width: parent.width
    }

    Rectangle {
        id: content
        color: "#e0fae7"
        anchors.top: header.bottom
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: parent.left

        DeviceList {
            anchors.fill: parent
            id: screenDeviceList
        }
        DeviceScreen {
            anchors.fill: parent
            id: screenDeviceDetails
        }
        Settings {
            anchors.fill: parent
            id: screenSettings
        }

        state: "DeviceList"
        states: [
            State {
                name: "DeviceList"

                PropertyChanges {
                    target: screenDeviceList
                    visible: true
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
            },
            State {
                name: "DeviceDetails"

                PropertyChanges {
                    target: screenDeviceList
                    visible: false
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    visible: true
                }
                PropertyChanges {
                    target: screenSettings
                    visible: false
                }
                StateChangeScript {
                    name: "secondScript"
                    script: screenDeviceDetails.loadDevice()
                }
            },
            State {
                name: "Settings"

                PropertyChanges {
                    target: screenDeviceList
                    visible: false
                }
                PropertyChanges {
                    target: screenDeviceDetails
                    myDevice: curentlySelectedDevice
                    visible: false
                }
                PropertyChanges {
                    target: screenSettings
                    visible: true
                }
            }
        ]
    }
}