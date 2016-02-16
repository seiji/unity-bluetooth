package com.bluetooth.cl;

import android.app.Activity;
import android.content.pm.PackageManager;

import com.bluetooth.BServiceUtil;
import com.bluetooth.IBService;
import com.unity3d.player.UnityPlayer;

/**
 * Created by seiji on 2/10/16.
 */
public class BCLService implements BCLServiceListener {
    private static final String TAG = "BLEService";

    private static final BCLService instance = new BCLService();
    private static IBService service = null;

    public static void createServiceClient() {
        if (service == null) {
            final Activity activity = UnityPlayer.currentActivity;
            if (!activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)) {
                return;
            }
            service = new BCLServiceClient(activity);
            ((BCLServiceBase) service).addListener(instance);
        }
    }

    public static void createServiceServer() {
        if (service == null) {
            final Activity activity = UnityPlayer.currentActivity;
            if (!activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_BLUETOOTH)) {
                return;
            }
            service = new BCLServiceServer(activity);
            ((BCLServiceBase) service).addListener(instance);
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

    @Override
    public void onDeviceConnect(boolean connect) {
        if (connect) {
            UnityPlayer.UnitySendMessage("BLECallback", "OnDidConnect", "");
        } else {
            UnityPlayer.UnitySendMessage("BLECallback", "OnDidDisconnect", "");
        }
    }

    @Override
    public void onSocketRead(final byte[] bytes) {
        String encoded = BServiceUtil.encodeBase64(bytes);
        UnityPlayer.UnitySendMessage("BLECallback", "OnDidReceiveWriteRequests", encoded);
    }

    @Override
    public void onSocketWrite(byte[] bytes) {

    }
}
