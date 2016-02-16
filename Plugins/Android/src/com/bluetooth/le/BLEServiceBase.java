package com.bluetooth.le;

import android.annotation.TargetApi;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothManager;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

import java.util.UUID;

/**
 * Created by seiji on 2/10/16.
 */
@TargetApi(Build.VERSION_CODES.KITKAT)
public class BLEServiceBase {
    private final static int REQUEST_ENABLE_BT = 10;
    protected static final String CHARACTERISTIC_UUID        = "7F855F82-9378-4508-A3D2-CD989104AF22";
    protected static final String CHARACTERISTIC_CONFIG_UUID = "00002902-0000-1000-8000-00805f9b34fb";

    protected Activity mActivity;
    protected BluetoothManager mBtManager;
    protected BluetoothAdapter mBtAdapter;

    protected UUID mServiceUUID = null;
    protected boolean mIsConnected = false;

    protected BluetoothGattCharacteristic mBtGattCharacteristic;

    public BLEServiceBase (final Activity activity) {
        mActivity = activity;
        mBtManager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
        mBtAdapter = mBtManager.getAdapter();

        // Check enable bluetooth
        if ((mBtAdapter == null) || (!mBtAdapter.isEnabled())) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        }
    }
}
