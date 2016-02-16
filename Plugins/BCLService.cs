using UnityEngine;
using System.Runtime.InteropServices;

public interface IBCLCallback
{
    void OnDidUpdateState();
    void OnDidConnect();
    void OnDidDisconnect();
    void OnDidReceiveWriteRequests(string base64String);
}

public class BCLService
{
    const string JAVA_CLASS_NAME = "com.bluetooth.cl.BCLService";

    public static void CreateServiceClient()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_ANDROID
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("createServiceClient");
         }
#endif
    }

    public static void CreateServiceServer()
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("createServiceServer");
         }
#endif
    }

    public static void StartService(string pairingAddress)
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("start", pairingAddress);
         }
#endif
    }

    public static void PauseService(bool isPause)
    {
#if UNITY_EDITOR || UNITY_STANDALONE_OSX
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
#elif UNITY_ANDROID 
         using (AndroidJavaClass plugin = new AndroidJavaClass(JAVA_CLASS_NAME))
         {
             plugin.CallStatic("write", data);
         }
#endif
    }
}
