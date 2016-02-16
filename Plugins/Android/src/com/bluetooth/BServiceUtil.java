package com.bluetooth;

import android.util.Base64;

import java.io.UnsupportedEncodingException;

/**
 * Created by seiji on 2/12/16.
 */
public class BServiceUtil {

    public static String encodeBase64(byte[] data) {
        if (data == null) {
            return null;
        }
        byte[] encode = Base64.encode(data, Base64.DEFAULT);
        String str = null;
        try {
            str = new String(encode, "UTF-8");
        } catch (UnsupportedEncodingException e) {
        }
        return str;
    }

    public static byte[] decodeBase64(String encoded) {
        if (encoded == null) {
            return null;
        }
        return Base64.decode(encoded, Base64.DEFAULT);
    }

    public static byte[] decodeBase64(byte[] encoded) {
        if (encoded == null) {
            return null;
        }
        return Base64.decode(encoded, Base64.DEFAULT);
    }
}
