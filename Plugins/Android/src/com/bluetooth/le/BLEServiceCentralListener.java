package com.bluetooth.le;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;

/**
 * Created by seiji on 1/24/16.
 */
public interface BLEServiceCentralListener {
    void onConnectionStateChange(BluetoothGatt gatt, int status, int newState);

    void onServicesDiscovered(BluetoothGatt gatt, int status);

    void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status);

    void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status);

    void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic);

    void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status);

    void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status);

    void onReliableWriteCompleted(BluetoothGatt gatt, int status);

    void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status);

    void onMtuChanged(BluetoothGatt gatt, int mtu, int status);
}
