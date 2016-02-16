package com.bluetooth.cl;

/**
 * Created by seiji on 2/12/16.
 */
public interface BCLServiceListener {

    void onDeviceConnect(boolean connect);

    void onSocketRead(final byte[] bytes);

    void onSocketWrite(final byte[] bytes);
}
