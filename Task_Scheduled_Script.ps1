# Get the current date and time in the specified format
$Date = Get-Date -Format "MM/dd/yyyy HH:mm"

<#
.SYNOPSIS
   Creates a temporary directory at C:\temp if it does not already exist.

.DESCRIPTION
   This function checks for the existence of a temporary directory at C:\temp. 
   If the directory does not exist, it creates one. If it already exists, 
   the function logs a message indicating its existence.

.OUTPUTS
   Creates the C:\temp directory if it does not exist or logs its existence.
#>
Function Create_Directory() {
    if (!(Test-Path C:\temp)) {
        New-Item -Path "C:\temp" -ItemType Directory -Force
    } else {
        "Temp Directory 'C:\temp' exists." | Out-File "C:\temp\Transcribe.log"
    }
}

<#
.SYNOPSIS
   Logs a message to a file.

.DESCRIPTION
   This function appends a log entry containing the current date, time, and a description to a log file.

.PARAMETER Description
   A description of the action or event to log.

.OUTPUTS
   Appends the log entry to the file C:\temp\Package_Deletion.log.
#>
Function Set-Logging($Description) {
    $Date + ":" + $Description | Out-File "C:\temp\Package_Deletion.log" -Append
}

<#
.SYNOPSIS
   Changes permissions for a registry key and its Owners subkey.

.DESCRIPTION
   This function grants Full Control permissions to the SYSTEM account 
   for the specified registry key and its Owners subkey.

.PARAMETER Package_Name
   The name of the registry key to modify permissions for.

.OUTPUTS
   Modifies the access permissions of the specified registry key and logs the changes.
#>
Function Change_Control($Package_Name) {
    Set-Logging("Changing permissions to Full Control for the SYSTEM profile for $Package_Name")
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package_Name)",
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::ChangePermissions
    )
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    Set-Logging("Permissions have been set to Full Control for the SYSTEM profile for $Package_Name")

    Set-Logging("Changing permissions to Full Control for the SYSTEM profile for $Package_Name\Owners")
    $Owner_key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        "SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package_Name)\Owners",
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::ChangePermissions
    )
    $Owner_acl = $Owner_key.GetAccessControl()
    $Owner_rule = New-Object System.Security.AccessControl.RegistryAccessRule("NT AUTHORITY\SYSTEM", "FullControl", "Allow")
    $Owner_acl.SetAccessRule($Owner_rule)
    $Owner_key.SetAccessControl($Owner_acl)
    Set-Logging("Permissions have been set to Full Control for the SYSTEM profile for $Package_Name\Owners")
}

<#
.SYNOPSIS
   Removes specified registry keys.

.DESCRIPTION
   This function deletes a list of registry keys and logs each deletion.

.PARAMETER Packages
   An array of registry keys to delete.

.OUTPUTS
   Deletes the specified registry keys and logs the operation.
#>
Function Remove_Packages($Packages) {
    foreach ($Package in $Packages) {
        Set-Logging("Removing $Package")
        reg delete $Package /f | Out-File -Append "C:\temp\Package_Deletion.log"
        Set-Logging("$Package has been removed.")
    }
}

<#
.SYNOPSIS
   Changes ownership of registry keys and deletes them.

.DESCRIPTION
   This function changes the ownership of specified registry keys to the SYSTEM account, 
   modifies permissions to grant Full Control, and then deletes the keys.

.PARAMETER Package_Name
   An array of registry keys to process.

.OUTPUTS
   Changes ownership and permissions of the registry keys, then deletes them. Logs all actions.
#>
Function Change_Ownership($Package_Name) {
    foreach ($Name in $Package_Name) {
        $Owner = Get-ACL $Name.Replace("HKEY_LOCAL_MACHINE", "HKLM:")

        $Name = $Name.Replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\", "").Trim()
        $Owner = $Owner.Owner
        Set-Logging("Original owner of $Name is $Owner")
        Set-Logging("Changing ownership for $Name")

        Change_Control($Name)

        $Acl = Get-Acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name"
        $identity = New-Object System.Security.Principal.NTAccount("NT AUTHORITY\SYSTEM")
        $Acl.SetOwner($identity)
        Set-Acl -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name" -AclObject $Acl

        $Owners_Acl = Get-Acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name\Owners"
        $Owners_Acl.SetOwner($identity)
        Set-Acl -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name\Owners" -AclObject $Owners_Acl

        $New_Owner = Get-Acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name"
        $New_Owner = $New_Owner.Owner
        Set-Logging("Current owner is now: $New_Owner")
    }
    Remove_Packages($Packages)
    New-Item -Path "C:\temp" -Name "Completed.txt" -ItemType File
}

# Main Script Execution

# Create the temporary directory
Create_Directory

# Retrieve the list of registry keys for the specified KB
$Packages = (Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*KB_PLACE_HOLDER*").Name

# Change ownership and delete the registry keys
Change_Ownership($Packages)
