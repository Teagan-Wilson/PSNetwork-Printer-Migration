#PS Network Printer Migration Script
#Teagan Wilson

Add-Type -AssemblyName System.DirectoryServices.AccountManagement

#Static
$OLDPrintServer = "STVDC"
$NEWPrintServer = "STVPRINT1"
$logpath = "C:" + $env:computername + ".log"
$SID = [System.DirectoryServices.AccountManagement.UserPrincipal]::Current.Sid.Value
#End Static


$beginMessage = "Begining migration on " + $env:computername + " at " + (Get-Date)
Add-Content $logpath $beginMessage
$SIDMessage = "USER SID :" + $SID
Add-Content $logpath $SIDMessage

#functions
function GetPrinters
{
	param( [string]$Old)
	#Get All Network Printer Connection Paths
	
	$InstalledPrinters = @()
	$combinedPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\" + $SID + "\Printers\Connections"
    $printers = Get-ChildItem -Path $combinedPath
		Foreach ($printer in $printers)
		{
		if ($Old)
			{
			if ($printer.Name -like "*" + $OLDPrintServer + "*")
				{$InstalledPrinters += $printer}
			}
		else
			{
			if ($printer.Name -like "*" + $NEWPrintServer + "*")
				{$InstalledPrinters += $printer}
			}
		}

	
	#Add PrinterName Attrib
	$installedPrinters | Add-Member -Name 'PrinterName' -MemberType NoteProperty -Value ""
	
	#Split Printer name from the reg name and populate the Printername attrib
    Foreach ($printer in $installedPrinters)
    {
        $printer.PrinterName = $printer.name.split(",")[3]
    }
    return $InstalledPrinters
}

function UninstallPrinter
{
    param( [string]$Printername )
	
	#Attempt Global Removal
	$logmessage = "rundll32.exe PRINTUI.DLL PrintUIEntry /gd /n\\$OLDPrintServer\$PrinterName /Gw /q"
	Add-Content $logpath $logmessage
    rundll32.exe PRINTUI.DLL PrintUIEntry /gd /n\\$OLDPrintServer\$PrinterName /Gw /q
	
	#Attempt Local Removal
	$logmessage = "rundll32.exe PRINTUI.DLL PrintUIEntry /gd /n\\$OLDPrintServer\$PrinterName /Gw /q"
	Add-Content $logpath $logmessage
    rundll32.exe PRINTUI.DLL PrintUIEntry /dn /n\\$OLDPrintServer\$PrinterName /Gw /q
	
	#Validate Uninstall
    $checkPrinters = GetPrinters -Old 1
    if ($checkPrinters.Name -like "*" + $Printername + "*")
    {
        $errorUninstallMessage = "WARNING! Failed to uninstall: " + $Printername
        Add-Content $logpath $errorUninstallMessage
        return 0
    }
    else
    {
        $errorUninstallMessage = "Uninstalled successfully: " + $Printername
        Add-Content $logpath $errorUninstallMessage
    return 1}
}

function InstallPrinter
{
    param( [string]$Printername )
    #Attempt Install
	$logmessage = "rundll32.exe PRINTUI.DLL PrintUIEntry /in /n\\$NEWPrintServer\$PrinterName /Gw /q"
	Add-Content $logpath $logmessage
    rundll32.exe PRINTUI.DLL PrintUIEntry /in /n\\$NEWPrintServer\$PrinterName /Gw /q
    $checkPrinters = GetPrinters -Old 0
    if ($checkPrinters.Name -like "*" + $Printername + "*")
    {
        $errorUninstallMessage = "WARNING! Failed to install: " + $Printername
        Add-Content $logpath $errorUninstallMessage
        return 0
    }
    else
    {
        $errorUninstallMessage = "Installed successfully: " + $Printername
        Add-Content $logpath $errorUninstallMessage
        return 1
    }
}
#end functions

#Uninstall
$InstalledPrinters = GetPrinters -Old 1
Add-Content $logpath $InstalledPrinters
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
