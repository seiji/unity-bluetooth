package com.bluetooth.le;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;

/**
 * Created by seiji on 2/10/16.
 */
public interface BLEServicePeripheralListener {
    void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic);

    void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value);

    void onConnectionStateChange(BluetoothDevice device, int status, int newState);

    void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattDescriptor descriptor);

    void onDescriptorWriteRequest(BluetoothDevice device, int requestId, BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value);

    void onExecuteWrite(BluetoothDevice device, int requestId, boolean execute);

    void onMtuChanged(BluetoothDevice device, int mtu);

    void onNotificationSent(BluetoothDevice device, int status);

    void onServiceAdded(int status, BluetoothGattService service);
}
