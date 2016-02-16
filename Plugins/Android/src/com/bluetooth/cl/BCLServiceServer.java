package com.bluetooth.cl;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothServerSocket;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.util.Log;

import com.bluetooth.IBService;

import java.io.IOException;
import java.util.UUID;

/**
 * Created by seiji on 2/10/16.
 */
public class BCLServiceServer extends BCLServiceBase implements IBService {
    private static final String TAG = "BCLServiceServer";
    private AcceptThread mAcceptThread = null;
    private ConnectedThread mConnectedThread = null;

    public BCLServiceServer(final Activity activity) {
        super(activity);
    }

    @Override
    public void start(String pairingAddress) {
        mPairingAddress = pairingAddress;
        discoverableDevice();
    }

    @Override
    public void pause() {
        if (mAcceptThread != null) {
            mAcceptThread.cancel();
            mAcceptThread = null;
        }
        if (mConnectedThread != null) {
            mConnectedThread.cancel();
            mConnectedThread = null;
        }
        for (BCLServiceListener listener : listeners) {
            listener.onDeviceConnect(false);
        }
    }

    @Override
    public void resume() {
        discoverableDevice();
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

    private void discoverableDevice() {

        boolean bonded = false;
        for (BluetoothDevice device : mPairedDevices) {
            if (mPairingAddress.equals(device.getAddress())) {
                bonded = true;
                break;
            }
        }

        if (!bonded) {
            Intent discoverableIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_DISCOVERABLE);
            discoverableIntent.putExtra(BluetoothAdapter.EXTRA_DISCOVERABLE_DURATION, 300);
            mActivity.startActivity(discoverableIntent);
        }

        mAcceptThread = new AcceptThread();
        mAcceptThread.start();
    }

    private class AcceptThread extends Thread {
        private final BluetoothServerSocket mmServerSocket;

        private AcceptThread() {
            BluetoothServerSocket tmp = null;
            try {
                tmp = mBtAdapter.listenUsingRfcommWithServiceRecord("_", UUID.fromString(CHARACTERISTIC_UUID));
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }
            mmServerSocket = tmp;
        }

        public void run() {
            BluetoothSocket socket = null;
            while (true) {
                try {
                    socket = mmServerSocket.accept();
                } catch (IOException e) {
                    break;
                }

                if (socket != null) {
                    mConnectedThread = new ConnectedThread(socket);
                    mConnectedThread.start();
                    for (BCLServiceListener listener : listeners) {
                        listener.onDeviceConnect(true);
                    }
                    try {
                        mmServerSocket.close();
                    } catch (IOException e) {
                        Log.e(TAG, e.getMessage());
                    }
                    break;
                }
            }
        }

        public void cancel() {
            try {
                mmServerSocket.close();
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }
        }
    }
}
