using UnityEngine;
using System.Runtime.InteropServices;

public interface IBLECallback
{
    void OnDidUpdateState();
    void OnDidConnect();
    void OnDidDisconnect();
    void OnDidReceiveWriteRequests(string base64String);
}

public class BLEService
{
    const string JAVA_CLASS_NAME = "com.bluetooth.le.BLEService";

#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
	    [DllImport ("__Internal")]
	    private static extern void _iOSBLECreateServicePeripheral ();
	
	    [DllImport ("__Internal")]
        private static extern void _iOSBLECreateServiceCentral ();

	    [DllImport ("__Internal")]
	    private static extern void _iOSBLEServiceStart (string uuidString);
	
	    [DllImport ("__Internal")]
	    private static extern void _iOSBLEServicePause (bool isPause);
	
	    [DllImport ("__Internal")]
	    private static extern void _iOSBLEServiceStop ();
	
	    [DllImport ("__Internal")]
	    private static extern void _iOSBLEServiceWrite (byte[] data, int length, bool withResponse); 
#endif

    public static void CreateServicePeripheral()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLECreateServicePeripheral();
#elif UNITY_ANDROID
#endif
    }

    public static void CreateServiceCentral()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLECreateServiceCentral();
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("createServiceCentral");
         }
#endif
    }

    public static void StartService(string uuidString)
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLEServiceStart(uuidString);
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("start", uuidString);
         }
#endif
    }

    public static void PauseService(bool isPause)
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLEServicePause(isPause);
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("pause", isPause);
         }
#endif
    }
    public static void StopService()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLEServiceStop();
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("stop");
         }
#endif
    }

    public static void Write(byte[] data, int length, bool withResponse)
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_IPHONE
        _iOSBLEServiceWrite(data, length, withResponse);
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("write", data);
         }
#endif
    }
}
