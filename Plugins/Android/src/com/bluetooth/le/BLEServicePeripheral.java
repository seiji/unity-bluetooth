package com.bluetooth.le;

import android.annotation.TargetApi;
import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattServer;
import android.bluetooth.BluetoothGattServerCallback;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.os.Build;
import android.os.ParcelUuid;

import com.bluetooth.IBService;

import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Queue;
import java.util.UUID;
import java.util.concurrent.ConcurrentLinkedQueue;

/**
 * Created by seiji on 2/10/16.
 */
public class BLEServicePeripheral extends BLEServiceBase implements IBService {

    private static final String TAG = "BLEServicePeripheral";

    private BluetoothLeAdvertiser mBtAdvertiser;
    private BluetoothGattServer mBtGattServer;

    private BluetoothLeAdvertiser mBleAdvertiser;
    private AdvertiseData.Builder mDataBuilder;
    private AdvertiseSettings.Builder mSettingsBuilder;
    private AdvertiseCallback mAdvertiseCallback = new AdvertiseCallback() {
        @Override
        public void onStartFailure(int errorCode) {
            super.onStartFailure(errorCode);
        }

        @Override
        public void onStartSuccess(AdvertiseSettings settingsInEffect) {
            super.onStartSuccess(settingsInEffect);
        }
    };

    private Queue<byte[]> mTransmitQueue = new ConcurrentLinkedQueue<byte[]>();

    private BluetoothDevice mConnectedDevice;

    ArrayList<BLEServicePeripheralListener> listeners = new ArrayList<BLEServicePeripheralListener>();

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    public BLEServicePeripheral(final Activity activity) {
        super(activity);

        mBtAdvertiser = mBtAdapter.getBluetoothLeAdvertiser();
        mBtGattCharacteristic = new BluetoothGattCharacteristic(
                UUID.fromString(CHARACTERISTIC_UUID),
                BluetoothGattCharacteristic.PROPERTY_NOTIFY | BluetoothGattCharacteristic.PROPERTY_READ | BluetoothGattCharacteristic.PROPERTY_WRITE
                , BluetoothGattDescriptor.PERMISSION_WRITE | BluetoothGattCharacteristic.PERMISSION_READ);
        BluetoothGattDescriptor dataDescriptor = new BluetoothGattDescriptor(
                UUID.fromString(CHARACTERISTIC_CONFIG_UUID),
                BluetoothGattDescriptor.PERMISSION_WRITE | BluetoothGattDescriptor.PERMISSION_READ);
        mBtGattCharacteristic.addDescriptor(dataDescriptor);
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    @Override
    public void start(String uuidString) {
        mServiceUUID = UUID.fromString(uuidString);
        if (mBtAdvertiser == null) {
            return;
        }

        BluetoothGattService btGattService = new BluetoothGattService(mServiceUUID, BluetoothGattService.SERVICE_TYPE_PRIMARY);
        btGattService.addCharacteristic(mBtGattCharacteristic);
        BluetoothGattServerCallback btGattServerCallback = createGattServerCallback(mServiceUUID, UUID.fromString(CHARACTERISTIC_UUID));
        mBtGattServer = mBtManager.openGattServer(mActivity.getApplicationContext(), btGattServerCallback);
        mBtGattServer.addService(btGattService);

        mDataBuilder = new AdvertiseData.Builder();
        mDataBuilder.setIncludeTxPowerLevel(false);
        mDataBuilder.addServiceUuid(new ParcelUuid(mServiceUUID));

        mSettingsBuilder=new AdvertiseSettings.Builder();
        mSettingsBuilder.setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED);
        mSettingsBuilder.setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH);

        mBleAdvertiser = mBtAdapter.getBluetoothLeAdvertiser();
        mBleAdvertiser.startAdvertising(mSettingsBuilder.build(), mDataBuilder.build(), mAdvertiseCallback);
    }

    @Override
    public void pause() {
        mBleAdvertiser.stopAdvertising(mAdvertiseCallback);
    }

    @Override
    public void resume() {
        mTransmitQueue = new ConcurrentLinkedQueue<byte[]>();
        mBleAdvertiser.startAdvertising(mSettingsBuilder.build(), mDataBuilder.build(), mAdvertiseCallback);
    }

    @Override
    public void stop() {
        pause();
        mBleAdvertiser = null;
        mBtAdapter = null;
    }

    @Override
    public void read() {
        // nothing
    }

    @Override
    public boolean write(byte[] data) {
        mTransmitQueue.offer(data);
        processTransmitQueue();
        return true;
    }

    private void processTransmitQueue() {
        byte[] data = mTransmitQueue.poll();
        if (data != null) {
            while (mBtGattCharacteristic.setValue(data)
                    && mBtGattServer.notifyCharacteristicChanged(mConnectedDevice, mBtGattCharacteristic, false)
                    && mIsConnected ) {
                data = mTransmitQueue.poll();
                if (data == null) {
                    break;
                }
            }
        }
    }

    public void addListener(BLEServicePeripheralListener listener){
        listeners.add(listener);
    }

    @TargetApi(Build.VERSION_CODES.LOLLIPOP)
    private BluetoothGattServerCallback createGattServerCallback(final UUID serviceUUID, final UUID characteristicUUID) {
        return new BluetoothGattServerCallback() {

            @Override
            public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic) {
                super.onCharacteristicReadRequest(device, requestId, offset, characteristic);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onCharacteristicReadRequest(device, requestId, offset, characteristic);
                }
            }

            @Override
            public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
                super.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value);
                if (responseNeeded) {
                    mBtGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value);
                }
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onCharacteristicWriteRequest(device, requestId, characteristic, preparedWrite, responseNeeded, offset, value);
                }
            }

            @Override
            public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
                super.onConnectionStateChange(device, status, newState);
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    mIsConnected = true;
                    mConnectedDevice = device;
                } else {
                    mIsConnected = false;
                }
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onConnectionStateChange(device, status, newState);
                }
            }

            @Override
            public void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattDescriptor descriptor) {
                super.onDescriptorReadRequest(device, requestId, offset, descriptor);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onDescriptorReadRequest(device, requestId, offset, descriptor);
                }
            }

            @Override
            public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
                super.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value);
                if (responseNeeded) {
                    mBtGattServer.sendResponse(device, requestId, BluetoothGatt.GATT_SUCCESS, 0, value);
                }
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onDescriptorWriteRequest(device, requestId, descriptor, preparedWrite, responseNeeded, offset, value);
                }
            }

            @Override
            public void onExecuteWrite(BluetoothDevice device, int requestId, boolean execute) {
                super.onExecuteWrite(device, requestId, execute);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onExecuteWrite(device, requestId, execute);
                }
            }

            @Override
            public void onMtuChanged(BluetoothDevice device, int mtu) {
                super.onMtuChanged(device, mtu);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onMtuChanged(device, mtu);
                }
            }

            @Override
            public void onNotificationSent(BluetoothDevice device, int status) {
                super.onNotificationSent(device, status);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onNotificationSent(device, status);
                }
            }

            @Override
            public void onServiceAdded(int status, BluetoothGattService service) {
                super.onServiceAdded(status, service);
                for (BLEServicePeripheralListener listener:listeners){
                    listener.onServiceAdded(status, service);
                }
            }
        };
    }
}
