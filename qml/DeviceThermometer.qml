/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2019 Emeric Grange - All Rights Reserved
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

import com.watchflower.theme 1.0

Item {
    id: deviceThermometer
    width: 450
    height: 700

    property var myDevice: curentlySelectedDevice

    Connections {
        target: myDevice
        onStatusUpdated: updateHeader()
        onLimitsUpdated: updateDatas()
        onDatasUpdated: updateDatas()
    }

    Connections {
        target: header
        onDeviceDatasButtonClicked: {
            header.setActiveDeviceDatas()
        }
        onDeviceSettingsButtonClicked: {
            header.setActiveDeviceSettings()
        }
        onRightMenuClicked: {
            // mobile only
        }
    }

    Timer {
        interval: 60000; running: true; repeat: true;
        onTriggered: updateStatusText()
    }

    onHeightChanged: {
        // update tempBox height
        tempBox.height = ((height * 0.4) > 256) ? (height * 0.4) : 256
    }

    function loadDevice() {
        if (typeof myDevice === "undefined") return
        //console.log("DeviceThermometer // loadDevice() >> " + myDevice)

        deviceScreenChart.loadGraph()
        updateHeader()
        updateDatas()
    }

    function updateHeader() {
        if (typeof myDevice === "undefined" || !myDevice) return
        //console.log("DeviceThermometer // updateHeader() >> " + myDevice)

        // Sensor battery level
        if (myDevice.deviceBattery > 95) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_full-24px.svg";
        } else if (myDevice.deviceBattery > 90) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_90-24px.svg";
        } else if (myDevice.deviceBattery > 70) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_80-24px.svg";
        } else if (myDevice.deviceBattery > 60) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_60-24px.svg";
        } else if (myDevice.deviceBattery > 40) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_50-24px.svg";
        } else if (myDevice.deviceBattery > 30) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_30-24px.svg";
        } else if (myDevice.deviceBattery > 20) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_20-24px.svg";
        } else if (myDevice.deviceBattery > 1) {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_alert-24px.svg";
        } else {
            imageBattery.source = "qrc:/assets/icons_material/baseline-battery_unknown-24px.svg";
        }

        // Location
        if (myDevice.deviceLocationName === "")
            imageEditLocation.visible = true

        textInputLocation.text = myDevice.deviceLocationName

        // Status
        updateStatusText()
    }

    function updateDatas() {
        if (typeof myDevice === 'undefined' || !myDevice) return
        //console.log("DeviceThermometer // updateDatas() >> " + myDevice)

        if (myDevice.deviceTempC > -40)
            sensorTemp.text = myDevice.getTempString()
        else
            sensorTemp.text = "?"
        if (myDevice.deviceHygro > 0)
            sensorHygro.text = myDevice.deviceHygro + "%"
        else
            sensorHygro.text = qsTr("loading...")

        deviceScreenChart.updateGraph()
    }

    function updateStatusText() {
        if (typeof myDevice === "undefined") return
        //console.log("DeviceThermometer // updateStatusText() >> " + myDevice)
/*
        textStatus.color = "#000"
        textStatus.font.bold = false

        if (myDevice) {
            textStatus.text = ""
            if (myDevice.updating) {
                textStatus.text = qsTr("Updating... ")
            } else {
                if (!myDevice.available) {
                    textStatus.text = qsTr("Offline! ")
                    textStatus.color = Theme.colorRed
                    textStatus.font.bold = true
                }
            }

            if (myDevice.lastUpdateMin >= 0) {
                if (myDevice.lastUpdateMin <= 1)
                    textStatus.text += qsTr("Just updated!")
                else if (myDevice.available)
                    textStatus.text += qsTr("Updated") + " " + myDevice.lastUpdateStr + " " + qsTr("ago")
                else
                    textStatus.text += qsTr("Last update") + " " + myDevice.lastUpdateStr + " " + qsTr("ago")
            }
        }
*/
    }

    ////////////////////////////////////////////////////////////////////////////

    Rectangle {
        id: tempBox
        height: 256
        color: Theme.colorHeader
        anchors.top: parent.top
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        Text {
            id: sensorTemp
            anchors.verticalCenterOffset: -40
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("22.0°")
            font.bold: false
            font.pixelSize: 48
            color: Theme.colorHeaderContent
        }

        Text {
            id: sensorHygro
            anchors.top: sensorTemp.bottom
            anchors.topMargin: 8
            anchors.horizontalCenter: parent.horizontalCenter

            text: qsTr("50%")
            font.bold: false
            font.pixelSize: 24
            color: Theme.colorHeaderContent
        }

        ImageSvg {
            id: imageBattery
            width: 32
            height: 32
            rotation: 90
            anchors.left: parent.left
            anchors.leftMargin: 8

            source: "qrc:/assets/icons_material/baseline-battery_unknown-24px.svg"
            color: Theme.colorHeaderContent
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
        }

        Item {
            id: itemLocation
            height: 32
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 8

            TextInput {
                id: textInputLocation
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                padding: 4
                color: Theme.colorHeaderContent
                font.pixelSize: 18
                font.bold: true
                onEditingFinished: {
                    if (text) {
                        imageEditLocation.visible = false
                    } else {
                        imageEditLocation.visible = true
                    }

                    myDevice.setLocationName(text)
                    focus = false
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true

                    onEntered: { imageEditLocation.visible = true; }
                    onExited: {
                        if (textInputLocation.text) {
                            imageEditLocation.visible = false
                        } else {
                            imageEditLocation.visible = true
                        }
                    }

                    onClicked: {
                        imageEditLocation.visible = true;
                        mouse.accepted = false;
                    }
                    onPressed: {
                        imageEditLocation.visible = true;
                        mouse.accepted = false;
                    }
                    onReleased: mouse.accepted = false;
                    onDoubleClicked: mouse.accepted = false;
                    onPositionChanged: mouse.accepted = false;
                    onPressAndHold: mouse.accepted = false;
                }
            }

            ImageSvg {
                id: imageEditLocation
                width: 24
                height: 24
                anchors.left: textInputLocation.left
                anchors.leftMargin: -24
                anchors.verticalCenterOffset: 0
                anchors.verticalCenter: parent.verticalCenter

                visible: false
                source: "qrc:/assets/icons_material/baseline-edit-24px.svg"
                color: Theme.colorHeaderContent
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////

    Item {
        id: graphBox
        anchors.top: tempBox.bottom
        anchors.topMargin: 0
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.right: parent.right
        anchors.rightMargin: 0

        DeviceScreenAioCharts {
            id: deviceScreenChart
            anchors.fill: parent
        }
    }
}
