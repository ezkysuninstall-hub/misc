Add-Type -AssemblyName System.Windows.Forms
$code = @"
using System;
using System.Runtime.InteropServices;

public class DisplayHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Auto)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
    }

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int ChangeDisplaySettingsEx(string lpszDeviceName, ref DEVMODE lpDevMode, IntPtr hwnd, int dwflags, IntPtr lParam);
}
"@
Add-Type -TypeDefinition $code

foreach ($screen in [System.Windows.Forms.Screen]::AllScreens) {
    $current = New-Object DisplayHelper+DEVMODE
    $current.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($current)
    [DisplayHelper]::EnumDisplaySettings($screen.DeviceName, -1, [ref]$current) | Out-Null

    $maxHz = $current.dmDisplayFrequency
    $bestMode = $current
    $i = 0
    $mode = New-Object DisplayHelper+DEVMODE
    $mode.dmSize = [System.Runtime.InteropServices.Marshal]::SizeOf($mode)

    while ([DisplayHelper]::EnumDisplaySettings($screen.DeviceName, $i, [ref]$mode)) {
        if ($mode.dmPelsWidth -eq $current.dmPelsWidth -and $mode.dmPelsHeight -eq $current.dmPelsHeight -and $mode.dmDisplayFrequency -gt $maxHz) {
            $maxHz = $mode.dmDisplayFrequency
            $bestMode = $mode
        }
        $i++
    }

    if ($maxHz -gt $current.dmDisplayFrequency) {
        [DisplayHelper]::ChangeDisplaySettingsEx($screen.DeviceName, [ref]$bestMode, [IntPtr]::Zero, 1, [IntPtr]::Zero) | Out-Null
        Write-Host "Updated $($screen.DeviceName) to $($maxHz)Hz"
    } else {
        Write-Host "$($screen.DeviceName) is already at max ($($maxHz)Hz)"
    }
}
