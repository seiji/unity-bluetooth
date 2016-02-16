package com.bluetooth.le;

import android.annotation.TargetApi;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.bluetooth.le.ScanCallback;
import android.os.Build;
import android.util.Log;

import com.bluetooth.IBService;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.UUID;

/**
 * Created by seiji on 1/23/16.
 */

@TargetApi(Build.VERSION_CODES.KITKAT)
public class BLEServiceCentral extends BLEServiceBase implements IBService {

    private static final String TAG = "BLEServiceCentral";

    private BluetoothGatt mBleGatt;
    private BluetoothGattCallback mBtGattCallback = null;

    private BluetoothAdapter.LeScanCallback mLeScanCallback;
    private ScanCallback mScanCallback;

    ArrayList<BLEServiceCentralListener> listeners = new ArrayList<BLEServiceCentralListener>();

    public BLEServiceCentral(final Activity activity) {
        super(activity);

        mLeScanCallback = new BluetoothAdapter.LeScanCallback() {
            @Override
            public void onLeScan(final BluetoothDevice device, final int rssi, final byte[] scanRecord) {
                activity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        scanResult(device, rssi, scanRecord);
                    }
                });
            }
        };
    }

    @Override
    public void start(String uuidString)
    {
        mServiceUUID = UUID.fromString(uuidString);
        mBtGattCallback = createGattCallback(mServiceUUID, UUID.fromString(CHARACTERISTIC_UUID));
        mBtAdapter.startLeScan(new UUID[]{mServiceUUID}, mLeScanCallback);
    }

    @Override
    public void pause() {
        if (mBleGatt != null) {
            mBleGatt.disconnect();
            mBleGatt.close();
            mBleGatt = null;
        }
        mIsConnected = false;
        mBtGattCharacteristic = null;
        mBtAdapter.stopLeScan(mLeScanCallback);
    }

    @Override
    public void resume() {
        mBtAdapter.startLeScan(new UUID[]{mServiceUUID}, mLeScanCallback);
    }

    @Override
    public void stop()
    {
        pause();
        mBtAdapter = null;
    }

    @Override
    public void read() {
        if (mIsConnected && mBleGatt != null && mBtGattCharacteristic != null) {
            mBleGatt.readCharacteristic(mBtGattCharacteristic);
        }
    }

    @Override
    public boolean write(byte[] data) {
        boolean ret = false;
        if (mIsConnected && mBleGatt != null && mBtGattCharacteristic != null) {
            ByteBuffer buf = ByteBuffer.wrap(data);
            buf.order(ByteOrder.BIG_ENDIAN);
            mBtGattCharacteristic.setValue(buf.array());
            ret = mBleGatt.writeCharacteristic(mBtGattCharacteristic);
        }
        return ret;
    }

    public void addListener(BLEServiceCentralListener listener){
        listeners.add(listener);
    }

    private void scanResult(BluetoothDevice device, int rssi, byte[] scanRecord)
    {
        if (!mIsConnected) {
            mBleGatt = device.connectGatt(mActivity.getApplicationContext(), false, mBtGattCallback);
        }
    }

    private BluetoothGattCallback createGattCallback(final UUID serviceUUID, final UUID characteristicUUID) {
        return new BluetoothGattCallback() {

            @Override
            public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
                super.onConnectionStateChange(gatt, status, newState);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onConnectionStateChange(gatt, status, newState);
                }
                Log.d(TAG, "onConnectionStateChange: " + newState);
                if (status == BluetoothGatt.GATT_SUCCESS && newState == BluetoothProfile.STATE_CONNECTED) {
                    gatt.discoverServices();
                } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    pause();
                    resume();
                }
            }

            @Override
            public void onServicesDiscovered(BluetoothGatt gatt, int status) {
                super.onServicesDiscovered(gatt, status);

                Log.d(TAG, "onServicesDiscovered: " + status);
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    BluetoothGattService service = gatt.getService(serviceUUID);
                    if (service != null)
                    {
                        mBtGattCharacteristic = service.getCharacteristic(characteristicUUID);
                        if (mBtGattCharacteristic != null && gatt.setCharacteristicNotification(mBtGattCharacteristic, true)) {
                            Log.d(TAG, "Connected: " + mBtGattCharacteristic.toString());

                            BluetoothGattDescriptor descriptor = mBtGattCharacteristic.getDescriptor(UUID.fromString(CHARACTERISTIC_CONFIG_UUID));
                            descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                            boolean ret = gatt.writeDescriptor(descriptor);
                            Log.d(TAG, "regist:" + ret);

                            mIsConnected = true;
                            for (BLEServiceCentralListener listener:listeners){
                                listener.onServicesDiscovered(gatt, status);
                            }
                        } else {
                            pause();
                        }
                    } else {
                        pause();
                    }
                }
            }

            @Override
            public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
                super.onCharacteristicRead(gatt, characteristic, status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onCharacteristicRead(gatt, characteristic, status);
                }
                Log.d(TAG, "onCharacteristicRead: " + status);
                final byte[] data = characteristic.getValue();
                if (status == BluetoothGatt.GATT_SUCCESS) {
                    try {
                        String result = new String(data, "UTF-8");
                        Log.d(TAG, "data:" + result);
                    } catch (UnsupportedEncodingException e) {
                        e.printStackTrace();
                    }
                }
            }

            @Override
            public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
                super.onCharacteristicWrite(gatt, characteristic, status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onCharacteristicWrite(gatt, characteristic, status);
                }
            }

            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
                super.onCharacteristicChanged(gatt, characteristic);
                Log.d(TAG, "onCharacteristicChanged: " + characteristic);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onCharacteristicChanged(gatt, characteristic);
                }
            }

            @Override
            public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
                super.onDescriptorRead(gatt, descriptor, status);
                Log.d(TAG, "onDescriptorRead: " + status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onDescriptorRead(gatt, descriptor, status);
                }
            }

            @Override
            public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {
                super.onDescriptorWrite(gatt, descriptor, status);
                Log.d(TAG, "onDescriptorWrite: " + status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onDescriptorWrite(gatt, descriptor, status);
                }
            }

            @Override
            public void onReliableWriteCompleted(BluetoothGatt gatt, int status) {
                super.onReliableWriteCompleted(gatt, status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onReliableWriteCompleted(gatt, status);
                }
            }

            @Override
            public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {
                super.onReadRemoteRssi(gatt, rssi, status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onReadRemoteRssi(gatt, rssi, status);
                }
            }

            @Override
            public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {
                super.onMtuChanged(gatt, mtu, status);
                for (BLEServiceCentralListener listener:listeners){
                    listener.onMtuChanged(gatt, mtu, status);
                }
            }
        };
    }
}
