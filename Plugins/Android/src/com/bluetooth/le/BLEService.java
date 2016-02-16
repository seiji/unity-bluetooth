package com.bluetooth.le;

import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.AlertDialog;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;
import android.content.DialogInterface;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Base64;
import android.util.Log;

import com.bluetooth.BServiceUtil;
import com.bluetooth.IBService;
import com.unity3d.player.UnityPlayer;

import java.io.UnsupportedEncodingException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

@TargetApi(Build.VERSION_CODES.KITKAT)
public class BLEService implements BLEServiceCentralListener, BLEServicePeripheralListener {

    private static final String TAG = "BLEService";
    private static final int PERMISSION_REQUEST_COARSE_LOCATION = 1;

    private static final BLEService instance = new BLEService();
    private static IBService service  = null;

    public static void createServiceCentral() {
        if (service == null) {
            final Activity activity = UnityPlayer.currentActivity;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            final AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                            builder.setTitle("This app needs location access");
                            builder.setMessage("Please grant location access so this app can detect beacons.");
                            builder.setPositiveButton(android.R.string.ok, null);
                            builder.setOnDismissListener(new DialogInterface.OnDismissListener()
                            {
                                @Override
                                @TargetApi(Build.VERSION_CODES.M)
                                public void onDismiss(DialogInterface dialog) {
                                    activity.requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST_COARSE_LOCATION);
                                }
                            });
                            builder.show();
                        }
                    });
                }
            }

            if (!activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
                return;
            }
            service = new BLEServiceCentral(activity);
            ((BLEServiceCentral)service).addListener(instance);
        }
    }

    public static void createServicePeripheral() {
        if (service == null) {
            final Activity activity = UnityPlayer.currentActivity;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (activity.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                    activity.runOnUiThread(new Runnable() {
                        @Override
                        public void run() {
                            final AlertDialog.Builder builder = new AlertDialog.Builder(activity);
                            builder.setTitle("This app needs location access");
                            builder.setMessage("Please grant location access so this app can detect beacons.");
                            builder.setPositiveButton(android.R.string.ok, null);
                            builder.setOnDismissListener(new DialogInterface.OnDismissListener()
                            {
                                @Override
                                @TargetApi(Build.VERSION_CODES.M)
                                public void onDismiss(DialogInterface dialog) {
                                    activity.requestPermissions(new String[]{Manifest.permission.ACCESS_COARSE_LOCATION}, PERMISSION_REQUEST_COARSE_LOCATION);
                                }
                            });
                            builder.show();
                        }
                    });
                }
            }

            if (!activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH_LE)) {
                return;
            }
            service = new BLEServicePeripheral(activity);
            ((BLEServicePeripheral)service).addListener(instance);
        }
    }

    public static void start(String uuidString) {
        if (service != null) {
            service.start(uuidString);
        }
    }

    public static void pause() {
        if (service != null) {
            service.pause();
        }
    }

    public static void stop() {
        if (service != null) {
            service.stop();
        }
    }

    public static void write(byte[] data) {
        if (service != null) {
            service.write(data);
        }
    }

    // BLECentralListener
    @Override
    public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
        if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            UnityPlayer.UnitySendMessage("BLECallback", "OnDidDisconnect", "");
        }
    }

    @Override
    public void onServicesDiscovered(BluetoothGatt gatt, int status) {
        UnityPlayer.UnitySendMessage("BLECallback", "OnDidConnect", "");
    }

    @Override
    public void onCharacteristicRead(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {

    }

    @Override
    public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {

    }

    @Override
    public void onCharacteristicChanged(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic) {
        final byte[] data = characteristic.getValue();
        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.order(ByteOrder.nativeOrder());
        String encoded = BServiceUtil.encodeBase64(buf.array());
        UnityPlayer.UnitySendMessage("BLECallback", "OnDidReceiveWriteRequests", encoded);
    }

    @Override
    public void onDescriptorRead(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {

    }

    @Override
    public void onDescriptorWrite(BluetoothGatt gatt, BluetoothGattDescriptor descriptor, int status) {

    }

    @Override
    public void onReliableWriteCompleted(BluetoothGatt gatt, int status) {

    }

    @Override
    public void onReadRemoteRssi(BluetoothGatt gatt, int rssi, int status) {

    }

    @Override
    public void onMtuChanged(BluetoothGatt gatt, int mtu, int status) {

    }

    // BLEPeripheralListener
    @Override
    public void onCharacteristicReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattCharacteristic characteristic) {

    }

    @Override
    public void onCharacteristicWriteRequest(BluetoothDevice device, int requestId, BluetoothGattCharacteristic characteristic, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {
        final byte[] data = characteristic.getValue();
        ByteBuffer buf = ByteBuffer.wrap(data);
        buf.order(ByteOrder.nativeOrder());
        String encoded = BServiceUtil.encodeBase64(buf.array());
        UnityPlayer.UnitySendMessage("BLECallback", "OnDidReceiveWriteRequests", encoded);
    }

    @Override
    public void onConnectionStateChange(BluetoothDevice device, int status, int newState) {
        if (newState == BluetoothProfile.STATE_CONNECTED) {
            UnityPlayer.UnitySendMessage("BLECallback", "OnDidConnect", "");
        } else {
            UnityPlayer.UnitySendMessage("BLECallback", "OnDidDisconnect", "");
        }
    }

    @Override
    public void onDescriptorReadRequest(BluetoothDevice device, int requestId, int offset, BluetoothGattDescriptor descriptor) {

    }

    @Override
    public void onDescriptorWriteRequest(BluetoothDevice device, int requestId, BluetoothGattDescriptor descriptor, boolean preparedWrite, boolean responseNeeded, int offset, byte[] value) {

    }

    @Override
    public void onExecuteWrite(BluetoothDevice device, int requestId, boolean execute) {

    }

    @Override
    public void onMtuChanged(BluetoothDevice device, int mtu) {

    }

    @Override
    public void onNotificationSent(BluetoothDevice device, int status) {

    }

    @Override
    public void onServiceAdded(int status, BluetoothGattService service) {

    }
}
