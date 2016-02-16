using UnityEditor;
using UnityEngine;
using System;

public class Packager
{
	public static void Export()
	{
        AssetDatabase.ExportPackage(
                new string[]{"Assets/Plugins"},
                "bluetoothservice.unitypackage",
                ExportPackageOptions.Recurse);
	}
}
