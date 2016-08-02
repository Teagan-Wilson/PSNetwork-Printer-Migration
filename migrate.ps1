
#PS Network Printer Migration Script
#Teagan Wilson
#Note: Enviroment Specific, Not for general consumption, without major customization.

#Statics
$OLDPrintServer = ""
$NEWPrintServer = ""


#Get installed network printers.
$InstalledPrinters = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\S-1-5-21-2032953301-1542742280-322568963-5881\Printers\Connections"
$InstalledPrinters | Add-Member -Name 'PrinterName' -MemberType NoteProperty -Value ""
Foreach ($printer in $installedPrinters)
{
$printer.PrinterName = $printer.name.split(",")[3]
}
$InstalledPrinters.PrinterName

#Get Default Printer
$DefaultPRN = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
$DefaultPRN | Add-Member -Name 'PrinterName' -MemberType NoteProperty -Value ""

#Filter path by slashes
$DefaultPRN.PrinterName = $DefaultPRN.Name.Split("\")[3]

#Just checking for logging sake
if ($InstalledPrinters.PrinterName -contains $DefaultPRN.PrinterName)
{
write-host "Default is network printer"
}
else
{
Write-Host "Default is not a network printer"
}

Foreach ($printer in $InstalledPrinters)
{
$PrinterName = $printer.PrinterName
rundll32.exe PRINTUI.DLL PrintUIEntry /dn /n\\$OLDPrintServer\$PrinterName Gw /q
}

Foreach ($printer in $InstalledPrinters)
{
$PrinterName = $printer.PrinterName
rundll32.exe PRINTUI.DLL PrintUIEntry /ga /n\\$NEWPrintServer\$printer.PrinterName Gw /q
}

