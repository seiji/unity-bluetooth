package com.bluetooth.cl;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.content.Intent;
import android.util.Log;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Set;

/**
 * Created by seiji on 2/10/16.
 */
public class BCLServiceBase {
    protected static final String CHARACTERISTIC_UUID = "7F855F82-9378-4508-A3D2-CD989104AF22";
    protected static final String CHARACTERISTIC_CONFIG_UUID = "00002902-0000-1000-8000-00805f9b34fb";
    private static final String TAG = "BCLServiceBase";
    private final static int REQUEST_ENABLE_BT = 10;

    protected Activity mActivity;
    protected BluetoothAdapter mBtAdapter;
    protected ArrayList<BluetoothDevice> mPairedDevices = new ArrayList<BluetoothDevice>();
    protected String mPairingAddress = null;
    ArrayList<BCLServiceListener> listeners = new ArrayList<BCLServiceListener>();

    public BCLServiceBase(final Activity activity) {
        mActivity = activity;
        mBtAdapter = BluetoothAdapter.getDefaultAdapter();

        // Check enable bluetooth
        if ((mBtAdapter == null) || (!mBtAdapter.isEnabled())) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            activity.startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        }

        Set<BluetoothDevice> pairedDevices = mBtAdapter.getBondedDevices();
        if (pairedDevices.size() > 0) {
            for (BluetoothDevice device : pairedDevices) {
                mPairedDevices.add(device);
            }
        }
    }

    public void addListener(BCLServiceListener listener) {
        listeners.add(listener);
    }

    protected class ConnectedThread extends Thread {
        private final BluetoothSocket mmSocket;
        private final InputStream mmInStream;
        private final OutputStream mmOutStream;

        public ConnectedThread(BluetoothSocket socket) {
            mmSocket = socket;
            InputStream tmpIn = null;
            OutputStream tmpOut = null;
            try {
                tmpIn = socket.getInputStream();
                tmpOut = socket.getOutputStream();
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }

            mmInStream = tmpIn;
            mmOutStream = tmpOut;
        }

        @Override
        public void run() {
            byte[] buffer = new byte[1024];

            while (true) {
                try {
                    int bytes = mmInStream.read(buffer);
                    if (bytes > 0 && bytes < buffer.length) {
                        byte[] data = Arrays.copyOfRange(buffer, 0, bytes);
                        ByteBuffer buf = ByteBuffer.wrap(data);
                        buf.order(ByteOrder.nativeOrder());
                        for (BCLServiceListener listener : listeners) {
                            listener.onSocketRead(buf.array());
                        }
                    }
                } catch (IOException e) {
                    break;
                }
            }
        }

        public void write(byte[] bytes) {
            ByteBuffer buf = ByteBuffer.wrap(bytes);
            buf.order(ByteOrder.BIG_ENDIAN);
            try {
                mmOutStream.write(buf.array());
                for (BCLServiceListener listener : listeners) {
                    listener.onSocketWrite(bytes);
                }
            } catch (IOException e) {
                Log.e(TAG, e.getMessage());
            }
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
