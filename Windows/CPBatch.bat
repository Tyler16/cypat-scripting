@echo off

ECHO "Turning on hacker font"
color 0A

ECHO "Disabling guest and administrator accounts"
net user Guest /active:no
net user Administrator /active:no

ECHO "Setting (some) password policies"
net accounts /minpwlen:8 /maxpwage:30 /minpwage:10 /lockoutduration:30 /lockoutthreshold:5 /lockoutwindow:30

ECHO "Enabling firewall"
netsh advfirewall set allprofiles state on

ECHO "Installing chocolatey and managing applications"
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command " [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
choco install notepadplusplus
choco upgrade notepadplusplus
choco install firefox
choco upgrade firefox
choco install ie11
choco upgrade ie11
choco upgrade putty
choco upgrade thunderbird
choco upgrade vlc
choco upgrade 7zip
choco uninstall wireshark -y
choco uninstall angryip -y
choco uninstall itunes -y
choco uninstall utorrent -y
choco uninstall teamviewer -y
choco uninstall nmap -y
choco uninstall kodi -y
choco uninstall winrar -y

ECHO "Disabling insecure services"
DISM /online /disable-feature /featurename:TelnetClient
DISM /online /disable-feature /featurename:TelnetServer
net stop msftpsvc
sc stop "TlntSvr"
sc config "TlntSvr" start= disabled
sc stop "RemoteRegistry"
sc config "RemoteRegistry" start= disabled

ECHO "Enabling all audit policies"
auditpol /set /category:* /success:enable
auditpol /set /category:* /failure:enable
