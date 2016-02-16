package com.bluetooth.cl;

import android.app.Activity;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.util.Log;

import com.bluetooth.IBService;

import java.io.IOException;
import java.util.UUID;

/**
 * Created by seiji on 2/10/16.
 */
public class BCLServiceClient extends BCLServiceBase implements IBService {

    private static final String TAG = "BCLServiceClient";

    private BroadcastReceiver mReceiver = null;
    private ConnectThread mConnectThread = null;
    private ConnectedThread mConnectedThread = null;

    public BCLServiceClient(final Activity activity) {
        super(activity);
    }

    @Override
    public void start(String pairingAddress) {
        mPairingAddress = pairingAddress;
        scanDevice();
    }

    @Override
    public void pause() {
        if (mReceiver != null) {
            mActivity.unregisterReceiver(mReceiver);
        }
        if (mConnectedThread != null) {
            mConnectThread.cancel();
            mConnectThread = null;
        }
        if (mConnectedThread !=  null) {
            mConnectedThread.cancel();
            mConnectedThread = null;
        }
        for (BCLServiceListener listener : listeners) {
            listener.onDeviceConnect(false);
        }
    }

    @Override
    public void resume() {
        scanDevice();
    }

    @Override
    public void stop() {
        pause();
    }

    @Override
    public void read() {

    }

    @Override
    public boolean write(byte[] data) {
        if (mConnectedThread != null) {
            mConnectedThread.write(data);
            return true;
        }
        return false;
    }

    private void scanDevice() {
        for (BluetoothDevice device : mPairedDevices) {
            if (mPairingAddress.equals(device.getAddress())) {
                mConnectThread = new ConnectThread(device);
                mConnectThread.start();
                for (BCLServiceListener listener : listeners) {
                    listener.onDeviceConnect(true);
                }
                return;
            }
        }
        mReceiver = createBroadcastReceiver(mPairingAddress);
        if (mBtAdapter.isDiscovering()) {
            mBtAdapter.cancelDiscovery();
        }

        IntentFilter filter = new IntentFilter();
        filter.addAction(BluetoothDevice.ACTION_FOUND);
        mActivity.registerReceiver(mReceiver, filter);
        mBtAdapter.startDiscovery();
    }

    private BroadcastReceiver createBroadcastReceiver(final String pairingAddress) {
        return new BroadcastReceiver() {
            public void onReceive(Context context, Intent intent) {
                String action = intent.getAction();
                if (BluetoothDevice.ACTION_FOUND.equals(action)) {
                    BluetoothDevice device = intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE);
                    if (device.getBondState() != BluetoothDevice.BOND_BONDED) {
                        if (pairingAddress.equals(device.getAddress())) {
                            mConnectThread = new ConnectThread(device);
                            mConnectThread.start();
                            for (BCLServiceListener listener : listeners) {
                                listener.onDeviceConnect(true);
                            }
                        }
                    }
                }
            }
        };
    }

    private class ConnectThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final BluetoothDevice mmDevice;

        protected ConnectThread(BluetoothDevice device) {
            BluetoothSocket tmp = null;
            mmDevice = device;

            try {
                tmp = device.createRfcommSocketToServiceRecord(UUID.fromString(CHARACTERISTIC_UUID));
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }
            mmSocket = tmp;
        }

        @Override
        public void run() {
            if (mBtAdapter.isDiscovering()) {
                mBtAdapter.cancelDiscovery();
            }
            try {
                mmSocket.connect();
            } catch (IOException connectException) {
                try {
                    mmSocket.close();
                } catch (IOException e) {
                    Log.e(TAG, e.getMessage());
                    return;
                }
            }
            mConnectedThread = new ConnectedThread(mmSocket);
            mConnectedThread.start();
        }

        public void cancel() {
            try {
                mmSocket.close();
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }
        }
    }
}