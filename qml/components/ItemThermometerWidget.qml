
import QtQuick 2.12
import QtQuick.Controls 2.12

import ThemeEngine 1.0

Item {
    id: thermoWidget
    anchors.fill: parent
    anchors.margins: 0

    property var widgetWidthTarget: (isPhone ? 48 : 64)
    property var widgetWidth: 64
    property var graphMin: currentDevice.tempMin
    property var graphMax: currentDevice.tempMax

    function loadGraph() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("thermoWidget // loadGraph() >> " + currentDevice)
    }

    function updateGraph() {
        if (typeof currentDevice === "undefined" || !currentDevice) return
        //console.log("thermoWidget // updateGraph() >> " + currentDevice)

        var days = Math.floor(width / widgetWidthTarget)
        widgetWidth = (width / days)
        currentDevice.updateAioMinMaxData(days)
    }

    onWidthChanged: updateGraph()

    function isIndicator() { return false }
    function resetHistoryMode() { }

    ////////////////////////////////////////////////////////////////////////////
/*
    Flickable {
        anchors.fill: parent

        contentWidth: row.width
        flickableDirection: Flickable.HorizontalFlick
        boundsBehavior: Flickable.StopAtBounds
*/
        Row {
            id: row
            height: parent.height
            anchors.right: parent.right
            spacing: 0

            //layoutDirection: Qt.RightToLeft

            Repeater {
                model: currentDevice.aioMinMaxData
                ItemThermometerWidgetBar { width: widgetWidth; mmd: modelData; }
            }
        }
    //}
}
