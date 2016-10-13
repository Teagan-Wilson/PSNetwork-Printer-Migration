#PS Network Printer Migration Script
#Teagan Wilson


#Static
$OLDPrintServer = ""
$NEWPrintServer = ""
$logpath = "" + $env:computername + ".log"
#End Static

#functions
function GetPrinters
{
$InstalledPrinters = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\S-1-5-21-2032953301-1542742280-322568963-5881\Printers\Connections"
$InstalledPrinters | Add-Member -Name 'PrinterName' -MemberType NoteProperty -Value ""
Foreach ($printer in $installedPrinters)
{
$printer.PrinterName = $printer.name.split(",")[3]
}
return $InstalledPrinters
}

function UninstallPrinter
{
param( [string]$Printername )
rundll32.exe PRINTUI.DLL PrintUIEntry /gd /n\\$OLDPrintServer\$PrinterName /Gw /q
rundll32.exe PRINTUI.DLL PrintUIEntry /dn /n\\$OLDPrintServer\$PrinterName /Gw /q
$checkPrinters = GetPrinters
if ($checkPrinters.Name -contains $Printername)
{
$errorUninstallMessage = "WARNING! Failed to uninstall: " + $Printername
Add-Content $logpath $errorUninstallMessage
return false
}
else
{
$errorUninstallMessage = "Uninstalled successfully: " + $Printername
Add-Content $logpath $errorUninstallMessage
return true}
}

function InstallPrinter
{
param( [string]$Printername )
rundll32.exe PRINTUI.DLL PrintUIEntry /in /n\\$NEWPrintServer\$PrinterName /Gw /q
$checkPrinters = GetPrinters
if ($checkPrinters.Name -inotcontains $Printername)
{
$errorUninstallMessage = "WARNING! Failed to install: " + $Printername
Add-Content $logpath $errorUninstallMessage
return false
}
else
{
$errorUninstallMessage = "Installed successfully: " + $Printername
Add-Content $logpath $errorUninstallMessage
return true
}
}
#end functions

#Uninstall
Foreach ($printer in $InstalledPrinters)
{
$PrinterName = $printer.PrinterName
$uninstallMessage = "Attempting Uninstall of :" + $PrinterName
Add-Content $logpath $uninstallMessage
$value = UninstallPrinter -Printername $PrinterName
if ($value)
{} else {UninstallPrinter -Printername $PrinterName}
}

#Install
Foreach ($printer in $InstalledPrinters)
{
$installMessage = "Attempting Install of :" + $PrinterName
Add-Content $logpath $installMessage
$PrinterName = $printer.PrinterName
InstallPrinter -PrinterName $PrinterName
}


