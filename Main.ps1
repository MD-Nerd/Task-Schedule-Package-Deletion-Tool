$Date = Get-Date -Format "MM/dd/yyyy HH:mm"

Function Set-Logging($Description)
{
    $Date + ":" + $Description | out-file "C:\temp\Package_Deletion.log" -append
    Write-Host $Date + ":" + $Description
}

Function Create_ScheduledTask()
{

    if(Get-ScheduledTask -TaskName Registry_Package_Deletion -ErrorAction SilentlyContinue)
     {
        Set-Logging("Scheduled task exists.")
     }
     else
     {
        Set-Logging("Scheduled task does not exist.")
        Set-Logging("Creating Scheduled Task.")
         $TaskScheduled_Action = New-ScheduledTaskAction -Execute "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "C:\temp\Task_Scheduled_Script.ps1"
         $Register_TaskScheduled_Event = Register-ScheduledTask -Action $TaskScheduled_Action -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -TaskName "Registry_Package_Deletion" -Description "This is part of the Microsoft Registry Package Deletion tool."
        Set-Logging("Schedule task has been created.")
     }
    

}

Function Start_ScheduledTask()
{
    Set-Logging("Starting scheduled task.")
    Start-ScheduledTask -TaskName Registry_Package_Deletion 
    Set-Logging("Scheduled Task started.")
}

<#Function Remove_Packages($Packages)
{
    forEach($Package in $Packages)
    {
       Set-Logging("Removing $Package")
       reg delete $package /f | out-file -append "C:\temp\Package_Deletion.log"
       Set-Logging("$Package has been removed.")
    }
}#>


<#Function Change_Control($Packages)
{
    forEach($package in $Packages)
    {

    $package = $package.replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\","").trim()

    Set-Logging("Giving full control to key owner for $package")
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package)",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("Builtin\Administrators","FullControl","Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    Set-Logging("full control has been given to key owner for $package")

    Set-Logging("Giving full control to key owner for $package")
    $Owner_key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package)\Owners",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $Owner_acl = $Owner_key.GetAccessControl()
    $Owner_rule = New-Object System.Security.AccessControl.RegistryAccessRule ("Builtin\Administrators","FullControl","Allow")
    $owner_acl.SetAccessRule($Owner_rule)
    $Owner_key.SetAccessControl($Owner_acl)
    Set-Logging("full control has been given to key owner for $package")
    }
}#>

Function Task_Scheduled_Status()
{
    $Task_Scheduled_Status = Get-ScheduledTask -TaskName Registry_Package_Deletion
    $Task_Scheduled_Status = $Task_Scheduled_Status.state
    Set-Logging("Waiting for Scheduled task to complete")
    $count = 0;
    while($Task_Scheduled_Status -ne "Ready")
    {
        if($count -eq 60)
        {
            Set-Logging("Task Scheduler has taken longer than 5 minutes to complete.")
            break
        }
        $Task_Scheduled_Status = Get-ScheduledTask -TaskName Registry_Package_Deletion
        $Task_Scheduled_Status = $Task_Scheduled_Status.state

        $count = $count++
        start-sleep -Seconds 5

    }
}

Function Refresh_ScheduledTask_Script()
{
    Set-Logging("Refreshing Scheduled Task script for next use.")
    $ScheduledTask_Script = get-content -Path "C:\temp\Task_Scheduled_Script.ps1"
    $ScheduledTask_Script = $ScheduledTask_Script -replace "$($KB_Number)","KB_PLACE_HOLDER"
    $ScheduledTask_Script | set-content -path "C:\temp\Task_Scheduled_Script.ps1"
    Set-Logging("Schedule Task script refreshed.")

}

Function Remove_ScheduledTask()
{
    Set-Logging("Removing Scheduled task.")
    Unregister-ScheduledTask -taskname Registry_Package_Deletion -Confirm:$false
    Set-Logging("Scheduled task removed.")
}



Write-Warning "This script is only meant to be used at the discretion of the Microsoft Support Engineer.
 Future uses without supervisory of a Microsoft Engineer are not supported."


Set-Logging("Requesting User input.")
$KB_Number = Read-Host "`nPlease enter the full KB number, for example, KB450765"
Set-Logging("User input: $KB_Number")


$Packages = (Get-item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*$($KB_Number)*").Name

$Task_Scheduled_Script = get-content -Path "C:\temp\Task_Scheduled_Script.ps1"
$Line_edit = $Task_Scheduled_Script -replace "KB_PLACE_HOLDER", "$($KB_Number)"
$Line_Edit | set-content -Path "C:\temp\Task_Scheduled_Script.ps1"


Create_ScheduledTask
Start_ScheduledTask
Task_Scheduled_Status
#Change_Control($Packages)
#Remove_Packages($Packages)


#Cleanup After

Refresh_ScheduledTask_Script
Remove_ScheduledTask
