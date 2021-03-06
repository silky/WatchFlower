/*!
 * This file is part of WatchFlower.
 * COPYRIGHT (C) 2020 Emeric Grange - All Rights Reserved
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
 * \date      2020
 * \author    Emeric Grange <emeric.grange@gmail.com>
 */

#include "device_hygrotemp_square.h"
#include "settingsmanager.h"
#include "utils_versionchecker.h"

#include <cmath>

#include <QBluetoothUuid>
#include <QBluetoothAddress>
#include <QBluetoothServiceInfo>
#include <QLowEnergyService>

#include <QSqlQuery>
#include <QSqlError>

#include <QDateTime>
#include <QTimeZone>

#include <QDebug>

/* ************************************************************************** */

DeviceHygrotempSquare::DeviceHygrotempSquare(QString &deviceAddr, QString &deviceName, QObject *parent):
    Device(deviceAddr, deviceName, parent)
{
    m_capabilities += DEVICE_BATTERY;
    m_capabilities += DEVICE_TEMPERATURE;
    m_capabilities += DEVICE_HUMIDITY;
}

DeviceHygrotempSquare::DeviceHygrotempSquare(const QBluetoothDeviceInfo &d, QObject *parent):
    Device(d, parent)
{
    m_capabilities += DEVICE_BATTERY;
    m_capabilities += DEVICE_TEMPERATURE;
    m_capabilities += DEVICE_HUMIDITY;
}

DeviceHygrotempSquare::~DeviceHygrotempSquare()
{
    delete serviceBattery;
    delete serviceData;
    delete serviceInfos;
}

/* ************************************************************************** */
/* ************************************************************************** */

void DeviceHygrotempSquare::serviceScanDone()
{
    //qDebug() << "DeviceHygrotempSquare::serviceScanDone(" << m_deviceAddress << ")";

    if (serviceBattery)
    {
        if (serviceBattery->state() == QLowEnergyService::DiscoveryRequired)
        {
            connect(serviceBattery, &QLowEnergyService::stateChanged, this, &DeviceHygrotempSquare::serviceDetailsDiscovered_battery);

            serviceBattery->discoverDetails();
        }
    }

    if (serviceData)
    {
        if (serviceData->state() == QLowEnergyService::DiscoveryRequired)
        {
            connect(serviceData, &QLowEnergyService::stateChanged, this, &DeviceHygrotempSquare::serviceDetailsDiscovered_data);
            //connect(serviceData, &QLowEnergyService::descriptorWritten, this, &DeviceHygrotempSquare::confirmedDescriptorWrite);
            //connect(serviceData, &QLowEnergyService::characteristicRead, this, &DeviceHygrotempSquare::bleReadDone);
            connect(serviceData, &QLowEnergyService::characteristicChanged, this, &DeviceHygrotempSquare::bleReadNotify);

            serviceData->discoverDetails();
        }
    }

    if (serviceInfos)
    {
        if (serviceInfos->state() == QLowEnergyService::DiscoveryRequired)
        {
            connect(serviceInfos, &QLowEnergyService::stateChanged, this, &DeviceHygrotempSquare::serviceDetailsDiscovered_infos);

            serviceInfos->discoverDetails();
        }
    }
}

void DeviceHygrotempSquare::addLowEnergyService(const QBluetoothUuid &uuid)
{
    //qDebug() << "DeviceHygrotempSquare::addLowEnergyService(" << uuid.toString() << ")";
/*
    if (uuid.toString() == "{0000180f-0000-1000-8000-00805f9b34fb}") // battery
    {
        delete serviceBattery;

        serviceBattery = controller->createServiceObject(uuid);
        if (!serviceBattery)
            qWarning() << "Cannot create service (battery) for uuid:" << uuid.toString();
    }
*/
    if (uuid.toString() == "{0000180a-0000-1000-8000-00805f9b34fb}") // infos
    {
        delete serviceInfos;
        serviceInfos = nullptr;

        if (m_firmware.isEmpty() || m_firmware == "UNKN")
        {
            serviceInfos = controller->createServiceObject(uuid);
            if (!serviceInfos)
                qWarning() << "Cannot create service (infos) for uuid:" << uuid.toString();
        }
    }

    if (uuid.toString() == "{ebe0ccb0-7a0a-4b0c-8a1a-6ff2997da3a6}") // (unknown service) // data
    {
        delete serviceData;
        serviceData = nullptr;

        serviceData = controller->createServiceObject(uuid);
        if (!serviceData)
            qWarning() << "Cannot create service (data) for uuid:" << uuid.toString();
    }
}

void DeviceHygrotempSquare::serviceDetailsDiscovered_data(QLowEnergyService::ServiceState newState)
{
    if (newState == QLowEnergyService::ServiceDiscovered)
    {
        //qDebug() << "DeviceHygrotempSquare::serviceDetailsDiscovered_data(" << m_deviceAddress << ") > ServiceDiscovered";

        if (serviceData)
        {
            SettingsManager *sm = SettingsManager::getInstance();

            // Characteristic "Units" // 1 byte READ WRITE // 0x00 - F, 0x01 - C    READ WRITE
            {
                QBluetoothUuid u(QString("EBE0CCBE-7A0A-4B0C-8A1A-6FF2997DA3A6")); // handler 0x??
                QLowEnergyCharacteristic chu = serviceData->characteristic(u);

                const quint8 *unit = reinterpret_cast<const quint8 *>(chu.value().constData());
                //qDebug() << "Units (0xFF: CELSIUS / 0x01: FAHRENHEIT) > " << chu.value();
                if (unit[0] == 0xFF && sm->getTempUnit() == "F")
                {
                    serviceData->writeCharacteristic(chu, QByteArray::fromHex("01"), QLowEnergyService::WriteWithResponse);
                }
                else if (unit[0] == 0x01 && sm->getTempUnit() == "C")
                {
                    serviceData->writeCharacteristic(chu, QByteArray::fromHex("FF"), QLowEnergyService::WriteWithResponse);
                }
            }

            // History
            //UUID_HISTORY = 'EBE0CCBC-7A0A-4B0C-8A1A-6FF2997DA3A6'   # Last idx 152          READ NOTIFY

            // Characteristic "Time" // 5 bytes READ WRITE
            {
                //QBluetoothUuid a(QString("EBE0CCB7-7A0A-4B0C-8A1A-6FF2997DA3A6")); // handler 0x??
                //QLowEnergyCharacteristic cha = serviceData->characteristic(a);
            }

            // Characteristic "Temp&Humi" // 3 bytes, READ NOTIFY
            {
                QBluetoothUuid th(QString("EBE0CCC1-7A0A-4B0C-8A1A-6FF2997DA3A6")); // handler 0x??
                QLowEnergyCharacteristic chth = serviceData->characteristic(th);
                m_notificationDesc = chth.descriptor(QBluetoothUuid::ClientCharacteristicConfiguration);
                serviceData->writeDescriptor(m_notificationDesc, QByteArray::fromHex("0100"));
            }
        }
    }
}

void DeviceHygrotempSquare::serviceDetailsDiscovered_infos(QLowEnergyService::ServiceState newState)
{
    if (newState == QLowEnergyService::ServiceDiscovered)
    {
        qDebug() << "DeviceHygrotempSquare::serviceDetailsDiscovered_infos(" << m_deviceAddress << ") > ServiceDiscovered";

        if (serviceInfos)
        {
            // Characteristic "Firmware Revision String"
            QBluetoothUuid f(QString("00002a26-0000-1000-8000-00805f9b34fb")); // handler 0x06
            QLowEnergyCharacteristic chf = serviceInfos->characteristic(f);
            if (chf.value().size() > 0)
            {
               m_firmware = chf.value();
            }

            if (m_firmware.size() == 10)
            {
                if (Version(m_firmware) >= Version(LATEST_KNOWN_FIRMWARE_HYGROTEMP_SQUARE))
                {
                    m_firmware_uptodate = true;
                    Q_EMIT sensorUpdated();
                }
            }
        }
    }
}

void DeviceHygrotempSquare::serviceDetailsDiscovered_battery(QLowEnergyService::ServiceState newState)
{
    if (newState == QLowEnergyService::ServiceDiscovered)
    {
        qDebug() << "DeviceHygrotempSquare::serviceDetailsDiscovered_battery(" << m_deviceAddress << ") > ServiceDiscovered";

        if (serviceBattery)
        {
            // Characteristic "Battery level"
            QBluetoothUuid b(QString("00002a19-0000-1000-8000-00805f9b34fb")); // handler 0x03
            QLowEnergyCharacteristic chb = serviceBattery->characteristic(b);

            if (chb.value().size() == 1)
            {
                const quint8 *data = reinterpret_cast<const quint8 *>(chb.value().constData());
                m_battery = static_cast<int>(data[0]);
                Q_EMIT sensorUpdated();
            }
        }
    }
}

/* ************************************************************************** */

void DeviceHygrotempSquare::bleWriteDone(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    //qDebug() << "DeviceHygrotempSquare::bleWriteDone(" << m_deviceAddress << ")";

    Q_UNUSED(c)
    Q_UNUSED(value)
}

void DeviceHygrotempSquare::bleReadDone(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    //qDebug() << "DeviceHygrotempSquare::bleReadDone(" << m_deviceAddress << ") on" << c.name() << " / uuid" << c.uuid() << value.size();

    Q_UNUSED(c)
    Q_UNUSED(value)
}

void DeviceHygrotempSquare::bleReadNotify(const QLowEnergyCharacteristic &c, const QByteArray &value)
{
    const quint8 *data = reinterpret_cast<const quint8 *>(value.constData());
/*
    qDebug() << "DeviceHygrotempSquare::bleReadNotify(" << m_deviceAddress << ") on" << c.name() << " / uuid" << c.uuid() << value.size();
    qDebug() << "WE HAVE DATA: 0x" \
             << hex << data[0] << hex << data[1] << hex << data[2] << hex << data[3] << hex << data[4];
*/
    if (c.uuid().toString().toUpper() == "{EBE0CCC1-7A0A-4B0C-8A1A-6FF2997DA3A6}")
    {
        // sensor data // handler 0x??

        if (value.size() == 5)
        {
            m_temp = static_cast<int16_t>(data[0] + (data[1] << 8)) / 100.f;
            m_hygro = data[2];

            float voltage = static_cast<int16_t>(data[3] + (data[4] << 8)) / 1000.f;
            //qDebug() << " voltage:" << voltage;

            int battery = static_cast<int>((voltage - 2.1f) * 100.f);
            if (battery < 0) battery = 0;
            if (battery > 100) battery = 100;
            m_battery = battery;

            m_lastUpdate = QDateTime::currentDateTime();

            //if (m_db)
            {
                // SQL date format YYYY-MM-DD HH:MM:SS
                QString tsStr = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:00:00");
                QString tsFullStr = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss");

                QSqlQuery addData;
                addData.prepare("REPLACE INTO datas (deviceAddr, ts, ts_full, temp, hygro)"
                                " VALUES (:deviceAddr, :ts, :ts_full, :temp, :hygro)");
                addData.bindValue(":deviceAddr", getAddress());
                addData.bindValue(":ts", tsStr);
                addData.bindValue(":ts_full", tsFullStr);
                addData.bindValue(":temp", m_temp);
                addData.bindValue(":hygro", m_hygro);
                if (addData.exec() == false)
                    qWarning() << "> addData.exec() ERROR" << addData.lastError().type() << ":" << addData.lastError().text();

                QSqlQuery updateDevice;
                updateDevice.prepare("UPDATE devices SET deviceFirmware = :firmware, deviceBattery = :battery WHERE deviceAddr = :deviceAddr");
                updateDevice.bindValue(":firmware", m_firmware);
                updateDevice.bindValue(":battery", m_battery);
                updateDevice.bindValue(":deviceAddr", getAddress());
                if (updateDevice.exec() == false)
                    qWarning() << "> updateDevice.exec() ERROR" << updateDevice.lastError().type() << ":" << updateDevice.lastError().text();
            }

            refreshDataFinished(true);
            controller->disconnectFromDevice();

#ifndef QT_NO_DEBUG
            qDebug() << "* DeviceHygrotempSquare update:" << getAddress();
            qDebug() << "- m_firmware:" << m_firmware;
            qDebug() << "- m_battery:" << m_battery;
            qDebug() << "- m_temp:" << m_temp;
            qDebug() << "- m_hygro:" << m_hygro;
#endif
        }
    }
}

void DeviceHygrotempSquare::confirmedDescriptorWrite(const QLowEnergyDescriptor &d, const QByteArray &value)
{
    //qDebug() << "DeviceHygrotempSquare::confirmedDescriptorWrite!";

    if (d.isValid() && d == m_notificationDesc && value == QByteArray::fromHex("0000"))
    {
        qDebug() << "confirmedDescriptorWrite() disconnect?!";

        //disabled notifications -> assume disconnect intent
        //m_control->disconnectFromDevice();
        //delete m_service;
        //m_service = nullptr;
    }
}
