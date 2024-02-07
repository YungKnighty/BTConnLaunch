Function Main {
	# Set powershell directory to script's root
	Set-Location $PSScriptRoot

	# MessageBox functionality
	Add-Type -AssemblyName System.Windows.Forms

	# TODO implement first time setup + later config

	# Init variables
	$AppName = "check"
	$AppFileExtension = "exe"
	$ExcludedName = "DS4Updater.exe"
	$BluetoothDeviceName = "Wireless Controller"
	$Debugging = $false

	# TODO implement file picker HACK JOB >:(
	$AppPath = Get-AppPath

	# Get BT Connectivity Data
	$BtStatus = Get-PnpDevice -class Bluetooth -FriendlyName $BluetoothDeviceName | 
	Get-PnpDeviceProperty -KeyName '{83DA6326-97A6-4088-9453-A1923F573B29} 15' |
	Select-Object -ExpandProperty Data

	# TODO make prettier dividers and columns for logging, use delims
	# $BluetoothDeviceName is connected
	If ($BtStatus) {
		if ($Debugging) { Set-Log "Info" "Connection:        $BluetoothDeviceName - FOUND" }
		
		# Start process if not already running
		if (-not (Get-Process -ErrorAction SilentlyContinue |
		Where-Object { $_.ProcessName -ne $ExcludedName -and $_.Path -eq $AppPath })) {
			Start-Process -FilePath $AppPath

			if ($Debugging) { Set-Log "Info" "Process:           $AppName.$AppFileExtension - START" }
		}
		
	# $BluetoothDeviceName not connected
	} else {
		if ($Debugging) { Set-Log "Info" "Connection:        $BluetoothDeviceName - NOT FOUND" }

		if (Get-Process -Name $AppName -ErrorAction SilentlyContinue |
		Where-Object { $_.ProcessName -ne $ExcludedName -and $_.Path -eq $AppPath }) {
			
			# Force stop process
			Get-Process -Name $AppName -ErrorAction SilentlyContinue |
			Where-Object { $_.ProcessName -like $AppName -and $_.ProcessName -ne $ExcludedName } |
			Stop-Process -Force

			if ($Debugging) { Set-Log "Info" "Process:           $AppName.$AppFileExtension - STOP" }
		}
	}

	if ($Debugging) {
		pause
	} else {
		exit
	}
}

# TODO finish comments
<#
.SYNOPSIS
Log an event to current directory.

.DESCRIPTION
When called, Log-Message writes the current time and given parameter, $Message, to a BTConnLog.txt file in the script's current 
directory (it creates this file if it does not currently exist).

.PARAMETER x

.PARAMETER x

.INPUTS
x

.OUTPUTS
x

#>
Function Set-Log {
	Param (
		[Parameter(Mandatory)]
		[ValidateSet("Success","Fail","Info")]
		[String]$Status,
		[Parameter(Mandatory)]
		[String]$Message
	)
	
	# Space formatting
	$StatusFormat = if ($Status -ne "Success") { "$Status   " } else { $Status }
	# Write to log
	Add-Content -Path "$PSScriptRoot\BTConnLog.log" -Value "$(Get-Date -Format `"dd/MM/yyyy | HH:mm:ss`") | $StatusFormat | $Message"
}

# TODO make comments
Function Get-AppPath {
	# Find first application's file path in current working dir
	# Exclude indicated variable from search
	($AppPath = Get-ChildItem -Filter ("$AppName.$AppFileExtension") -File | 
						Where-Object { $_.Name -ne $ExcludedName } |
						Select-Object -ExpandProperty FullName -First 1)
	
	if ($null -eq $AppPath) {
		if ($Debugging) { Set-Log "Fail" "$AppName.$AppFileExtension not found in current working directory." }
		
		# Prompt for application search or exit
		$msgBoxInput = [System.Windows.Forms.MessageBox]::Show("Specified application (" + $AppName + "." + $AppFileExtension + ") not found. Try searching again?",
															"Application Not Found",
															[System.Windows.Forms.MessageBoxButtons]::RetryCancel,
															"Error")
		# Reattempt search
		if ($msgBoxInput -eq "Retry") {
			Get-AppPath
		} 
		elseif ($msgBoxInput -eq "Cancel") {
			if ($Debugging) { pause } else { exit }
		}
	} else {
		if ($Debugging) { Set-Log "Success" "ApplicationPath:   $AppPath" }
	}
}

Main