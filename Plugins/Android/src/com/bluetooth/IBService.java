package com.bluetooth;

import java.util.UUID;

/**
 * Created by seiji on 1/23/16.
 */
public interface IBService {
    void start(String identifier);

    void pause();

    void resume();

    void stop();

    void read();

    boolean write(byte[] data);
}
