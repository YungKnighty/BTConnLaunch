# Set powershell directory to script's root
Set-Location $PSScriptRoot

# MessageBox functionality
Add-Type -AssemblyName System.Windows.Forms

<#
    .SYNOPSIS
    Log an event to current directory.

    .DESCRIPTION
    When called, Log-Message writes the current time and given parameter, $Message, to a BTConnLog.txt file in the script's current 
	directory (it creates this file if it does not currently exist).

    .PARAMETER Ip
    IP address of the OME server

    .PARAMETER Credentials
    Credentials for the OME server

    .INPUTS
    None. You cannot pipe objects to Invoke-Authenticate.

    .OUTPUTS
    hashtable. The Invoke-Authenticate function returns a hashtable with the headers resulting from authentication 
               against the OME server

  #>
Function Log-Message
{
	Param (
		[Parameter(Mandatory)]
		[ValidateSet("Success","Fail","Info")]
		[String]$Status,
		[Parameter(Mandatory)]
		[String]$Message
	)
	if (-not [System.IO.File]::Exists("$PSScriptRoot\BTConnLog.log")) {
		
	}
	
	$StatusFormat = if ($Status -ne "Success") { "$Status   " } else { $Status }
    Add-Content -Path "$PSScriptRoot\BTConnLog.log" -Value "$(Get-Date -Format `"dd/MM/yyyy | HH:mm:ss`") | $StatusFormat | $Message"
}

Function Check-ApplicationExist {
	($ApplicationPath = Get-ChildItem -Filter ($ApplicationProcessName + ".exe") -File | 
						Where-Object { $_.Name -ne $ExcludedName } |
						Select-Object -ExpandProperty FullName -First 1)
	if ($null -eq $ApplicationPath) {
        $msgBoxInput = [System.Windows.Forms.MessageBox]::Show("Specified application (" + $ApplicationProcessName + ".exe) not found. Try searching again?",
															"Bluetooth Launch Error",
															[System.Windows.Forms.MessageBoxButtons]::RetryCancel,
															"Error")
		if ($msgBoxInput -eq "Retry") {
			Check-ApplicationExist
		} elseif ($msgBoxInput -eq "Cancel") {
			exit
		}
	}
}

# Init variables
Set-Variable -name ApplicationProcessName -option Constant -value ([string]"DS4*")
Set-Variable -name ExcludedName -option Constant -value ([string]"DS4Updater.exe")
Set-Variable -name BluetoothDeviceName -option Constant -value ([string]"Wireless Controller")
Log-Message "Info" "Hi"
# Get BT Connectivity Data
$BtStatus = Get-PnpDevice -class Bluetooth -FriendlyName $BluetoothDeviceName | 
  Get-PnpDeviceProperty -KeyName '{83DA6326-97A6-4088-9453-A1923F573B29} 15' |
  Select -ExpandProperty Data

# $BluetoothDeviceName Connected
If ($BtStatus) {
	$ApplicationPath = Check-ApplicationExist
	
	# Start process if not already running
	if (-not (Get-Process -Name $ApplicationProcessName -ErrorAction SilentlyContinue |
				Where-Object { $_.ProcessName -like $ApplicationProcessName -and $_.ProcessName -ne $ExcludedName })) {
		Start-Process -FilePath $ApplicationPath
	}
	
# $BluetoothDeviceName Disconnected
} else {
	# Force stop process
	Get-Process -Name $ApplicationProcessName -ErrorAction SilentlyContinue |
		Where-Object { $_.ProcessName -like $ApplicationProcessName -and $_.ProcessName -ne $ExcludedName } |
		Stop-Process -Force
}
exit