import QtQuick 2.9
import QtQuick.Controls 2.2

import com.watchflower.theme 1.0
import "qrc:/qml/UtilsNumber.js" as UtilsNumber

RangeSlider {
    id: control
    first.value: 0.25
    second.value: 0.75
    snapMode: RangeSlider.SnapAlways

    property string unit: ""

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 200
        implicitHeight: 4
        width: control.availableWidth
        height: implicitHeight
        radius: 2
        color: Theme.colorYellow
        opacity: 0.9

        Rectangle {
            x: (control.first.visualPosition * parent.width)
            width: (control.second.visualPosition * parent.width) - x
            height: parent.height
            color: Theme.colorGreen
            radius: 2
        }
    }

    first.handle: Rectangle {
        x: control.leftPadding + first.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 22
        implicitHeight: 22
        width: t1.width * 1.4
        radius: 6
        color: Theme.colorGreen
        border.color: Theme.colorGreen
        opacity: first.pressed ? 0.9 : 1

        Text {
            id: t1
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var vvalue = first.value
                if (unit === "°" && settingsManager.tempUnit === "F") vvalue = UtilsNumber.tempCelsiusToFahrenheit(vvalue)
                vvalue = vvalue.toFixed(0)
                return ((first.value > 999) ? vvalue / 1000 : vvalue) + unit
            }
            font.pixelSize: 14
            color: "white"
        }
    }

    second.handle: Rectangle {
        x: control.leftPadding + second.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight / 2) - (height / 2)
        implicitWidth: 22
        implicitHeight: 22
        width: t2.width * 1.4
        radius: 6
        color: Theme.colorGreen
        border.color: Theme.colorGreen
        opacity: second.pressed ? 0.9 : 1

        Text {
            id: t2
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 1
            anchors.horizontalCenter: parent.horizontalCenter
            text: {
                var vvalue = second.value
                if (unit === "°" && settingsManager.tempUnit === "F") vvalue = UtilsNumber.tempCelsiusToFahrenheit(vvalue)
                vvalue = vvalue.toFixed(0)
                return ((first.value > 999) ? vvalue / 1000 : vvalue) + unit
            }
            font.pixelSize: 14
            color: "white"
        }
    }
}
