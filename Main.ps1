# Get the current date and time in the specified format
$Date = Get-Date -Format "MM/dd/yyyy HH:mm"

<#
.SYNOPSIS
   Logs actions and messages with timestamps.

.DESCRIPTION
   This function logs messages to a file and also outputs them to the console, 
   ensuring both persistent logging and user visibility.

.PARAMETER Description
   A description of the action or event to log.

.OUTPUTS
   Appends the log entry to the file C:\temp\Package_Deletion.log and outputs it to the console.
#>
Function Set-Logging($Description) {
    $Date + ":" + $Description | Out-File "C:\temp\Package_Deletion.log" -Append
    Write-Host $Date + ":" + $Description
}

<#
.SYNOPSIS
   Creates a scheduled task to execute a PowerShell script.

.DESCRIPTION
   This function checks for the existence of a scheduled task. 
   If the task does not exist, it creates a new task that runs a specified script with elevated privileges.

.OUTPUTS
   Creates the scheduled task or logs its existing status.
#>
Function Create_ScheduledTask() {
    if (Get-ScheduledTask -TaskName Registry_Package_Deletion -ErrorAction SilentlyContinue) {
        Set-Logging("Scheduled task exists.")
    } else {
        Set-Logging("Scheduled task does not exist.")
        Set-Logging("Creating Scheduled Task.")
        $TaskScheduled_Action = New-ScheduledTaskAction -Execute "C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe" -Argument "C:\temp\Task_Scheduled_Script.ps1"
        $Register_TaskScheduled_Event = Register-ScheduledTask -Action $TaskScheduled_Action -RunLevel Highest -User "NT AUTHORITY\SYSTEM" -TaskName "Registry_Package_Deletion" -Description "This is part of the Microsoft Registry Package Deletion tool."
        Set-Logging("Scheduled task has been created.")
    }
}

<#
.SYNOPSIS
   Starts the scheduled task.

.DESCRIPTION
   This function initiates the execution of the previously created scheduled task.

.OUTPUTS
   Starts the scheduled task and logs the action.
#>
Function Start_ScheduledTask() {
    Set-Logging("Starting scheduled task.")
    Start-ScheduledTask -TaskName Registry_Package_Deletion
    Set-Logging("Scheduled Task started.")
}

<#
.SYNOPSIS
   Monitors the status of the scheduled task until it completes.

.DESCRIPTION
   This function continuously checks the status of the scheduled task to ensure it completes within a reasonable time. 
   Logs any delays or completion status.

.OUTPUTS
   Logs the task status and waits until the task is completed or timeout occurs.
#>
Function Task_Scheduled_Status() {
    $Task_Scheduled_Status = Get-ScheduledTask -TaskName Registry_Package_Deletion
    $Task_Scheduled_Status = $Task_Scheduled_Status.State
    Set-Logging("Waiting for Scheduled task to complete")
    $count = 0
    while ($Task_Scheduled_Status -ne "Ready") {
        if ($count -eq 60) {
            Set-Logging("Task Scheduler has taken longer than 5 minutes to complete.")
            break
        }
        $Task_Scheduled_Status = Get-ScheduledTask -TaskName Registry_Package_Deletion
        $Task_Scheduled_Status = $Task_Scheduled_Status.State

        $count = $count++
        Start-Sleep -Seconds 5
    }
}

<#
.SYNOPSIS
   Resets the scheduled task script for future use.

.DESCRIPTION
   This function replaces the KB number placeholder in the scheduled task script with the original placeholder, 
   making it ready for future runs.

.OUTPUTS
   Updates the scheduled task script to its default state.
#>
Function Refresh_ScheduledTask_Script() {
    Set-Logging("Refreshing Scheduled Task script for next use.")
    $ScheduledTask_Script = Get-Content -Path "C:\temp\Task_Scheduled_Script.ps1"
    $ScheduledTask_Script = $ScheduledTask_Script -replace "$($KB_Number)", "KB_PLACE_HOLDER"
    $ScheduledTask_Script | Set-Content -Path "C:\temp\Task_Scheduled_Script.ps1"
    Set-Logging("Scheduled Task script refreshed.")
}

<#
.SYNOPSIS
   Removes the scheduled task.

.DESCRIPTION
   This function unregisters and removes the created scheduled task from the system.

.OUTPUTS
   Deletes the scheduled task and logs the action.
#>
Function Remove_ScheduledTask() {
    Set-Logging("Removing Scheduled task.")
    Unregister-ScheduledTask -TaskName Registry_Package_Deletion -Confirm:$false
    Set-Logging("Scheduled task removed.")
}

# Main Script Execution
<#
.SYNOPSIS
   Executes the main script flow.

.DESCRIPTION
   This section performs the following:
   1. Prompts the user for a KB number.
   2. Configures the scheduled task.
   3. Starts and monitors the scheduled task.
   4. Cleans up the scheduled task after execution.

.OUTPUTS
   Logs all actions performed during the script execution.
#>

Write-Warning "This script is only meant to be used at the discretion of the Microsoft Support Engineer. Future uses without supervisory of a Microsoft Engineer are not supported."

Set-Logging("Requesting User input.")
$KB_Number = Read-Host "`nPlease enter the full KB number, for example, KB450765"
Set-Logging("User input: $KB_Number")

# Retrieve the packages associated with the KB number
$Packages = (Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*$($KB_Number)*").Name

# Replace placeholder in the scheduled task script with the KB number
$Task_Scheduled_Script = Get-Content -Path "C:\temp\Task_Scheduled_Script.ps1"
$Line_edit = $Task_Scheduled_Script -replace "KB_PLACE_HOLDER", "$($KB_Number)"
$Line_Edit | Set-Content -Path "C:\temp\Task_Scheduled_Script.ps1"

# Create, start, and monitor the scheduled task
Create_ScheduledTask
Start_ScheduledTask
Task_Scheduled_Status

# Refresh and remove the scheduled task after execution
Refresh_ScheduledTask_Script
Remove_ScheduledTask
