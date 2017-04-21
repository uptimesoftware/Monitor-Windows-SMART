<#queries various WMI classes to output a coherent message for drives who have SMART technology for health monitoring and 
who have a predicted failure in their future. if there are no prediction, no output is returned.
NOTE: VMWare VMs do not have any SMART reporting, this only is known to work for physical machines.
written by Robert Vandervoort and Terry Woodside, 2017 - Idera Software
WMI queries lovingly reused from:
https://social.technet.microsoft.com/Forums/scriptcenter/en-US/f6a5783f-2869-4aef-ada4-52f0cebd469d/how-to-correlate-smart-status-with-drive-letter?forum=ITCG
John1519 https://social.technet.microsoft.com/profile/john1519?type=forum&referrer=http://social.technet.microsoft.com/Forums/office/en-US/f6a5783f-2869-4aef-ada4-52f0cebd469d/how-to-correlate-smart-status-with-drive-letter?forum=ITCG
With slight modifications #>

$UPT_USERNAME = Get-ChildItem Env:UPTIME_USERNAME | select -expand value;
$UPT_PASSWORD = Get-ChildItem Env:UPTIME_PASSWORD | select -expand value;
$UPT_HOSTNAME = Get-ChildItem Env:UPTIME_HOSTNAME | select -expand value;

#determine if running against localhost
if($UPT_HOSTNAME -eq 'localhost' -Or $UPT_HOSTNAME -eq (Get-ChildItem Env:USERDOMAIN | select -expand value)) {
	#write-host 'running local'
	$runninglocal = "true"
	}

#Retrieve data from WMI using authentication or not depending on choice
If($runninglocal) {
	$logidisk = gwmi –query "SELECT * FROM win32_logicaldisk WHERE DriveType = '3'"
	foreach ($ld in $logidisk) {
		$drvltr = $ld.DeviceID
		$free = $ld.FreeSpace
		$model = (gwmi win32_logicaldisk -filter "Name='$drvltr'").GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') |
			foreach { $_.Model }
		$deviceid = (gwmi win32_logicaldisk -filter "Name='$drvltr'").GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') | 
			foreach { $_.PNPDeviceID }
		$predict = gwmi -Namespace root\wmi –class MSStorageDriver_FailurePredictStatus | 
			Where-Object { $_.InstanceName -like "$deviceid*" } | foreach { $_.PredictFailure }
		If ($predict -eq "true") {
			write-host output Drive $drvltr of model $model, has a predicted failure via SMART reporting.
			}
	}
} ELSE {
    $credential = New-Object System.Management.Automation.PsCredential($UPT_USERNAME, (ConvertTo-SecureString $UPT_PASSWORD -AsPlainText -Force))
	$logidisk = gwmi -Credential $credential -ComputerName $UPT_HOSTNAME –query "SELECT * FROM win32_logicaldisk WHERE DriveType = '3'"
	foreach ($ld in $logidisk) {
		$drvltr = $ld.DeviceID
		$free = $ld.FreeSpace
		$model = (gwmi -Credential $credential -ComputerName $UPT_HOSTNAME win32_logicaldisk -filter "Name='$drvltr'").GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') |
			foreach { $_.Model }
		$deviceid = (gwmi -Credential $credential -ComputerName $UPT_HOSTNAME win32_logicaldisk -filter "Name='$drvltr'").GetRelated('Win32_DiskPartition').GetRelated('Win32_DiskDrive') | 
			foreach { $_.PNPDeviceID }
		$predict = gwmi -Credential $credential -ComputerName $UPT_HOSTNAME -Namespace root\wmi –class MSStorageDriver_FailurePredictStatus | 
			Where-Object { $_.InstanceName -like "$deviceid*" } | foreach { $_.PredictFailure }
		If ($predict -eq "true") {
			write-host output Drive $drvltr of model $model, has a predicted failure via SMART reporting.
			}
	}
}  