
$Date = Get-Date -Format "MM/dd/yyyy HH:mm"

Function Create_Directory()
{
    if(!(Test-path C:\temp))
    {
        New-Item -Path "C:\temp" -ItemType Directory -Force
    }
    else
    {
        "Temp Directory 'C:\temp' exists." | out-file "C:\temp\Transcribe.log"
    }
}

Function Set-Logging($Description)
{
    $Date + ":" + $Description | out-file "C:\temp\Package_Deletion.log" -append
}


Function Change_Control($Package_Name)
{
    Set-Logging("Changing permissions to Full Control for the SYSTEM profile for $Package_Name")
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package_Name)",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\SYSTEM","FullControl","Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    Set-Logging("Permissions have been set to Full Control for the SYSTEM profile for $Package_Name")

    Set-Logging("Changing permissions to Full Control for the SYSTEM profile for $Package_Name\Owners")
    $Owner_key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$($Package_Name)\Owners",[Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,[System.Security.AccessControl.RegistryRights]::ChangePermissions)
    $Owner_acl = $Owner_key.GetAccessControl()
    $Owner_rule = New-Object System.Security.AccessControl.RegistryAccessRule ("NT AUTHORITY\SYSTEM","FullControl","Allow")
    $owner_acl.SetAccessRule($Owner_rule)
    $Owner_key.SetAccessControl($Owner_acl)
    Set-Logging("Permissions have been set to Full Control for the SYSTEM profile for $Package_Name\Owners")
}

Function Remove_Packages($Packages)
{
    forEach($Package in $Packages)
    {
       Set-Logging("Removing $Package")
       reg delete $package /f | out-file -append "C:\temp\Package_Deletion.log"
       Set-Logging("$Package has been removed.")
    }
}


Function Change_Ownership($Package_Name)
{
    ForEach($Name in $Package_Name)
    {
        $Owner = Get-ACL $Name.replace("HKEY_LOCAL_MACHINE","HKLM:")


        $Name = $Name.replace("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\","").trim()
        $Owner = $Owner.Owner
        Set-Logging("Original owner of $Name is $Owner")
        Set-Logging ("Changing ownership for $Name")

        Change_Control($Name)

        $Acl =  get-acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name"
        $identity = New-Object System.Security.Principal.NTAccount("NT AUTHORITY\SYSTEM")
        $Acl.SetOwner($identity)
        Set-Acl -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name" -AclObject $ACL
        
        $Owners_Acl =  get-acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name\Owners"
        $Owners_identity = New-Object System.Security.Principal.NTAccount("NT AUTHORITY\SYSTEM")
        $Owners_Acl.SetOwner($identity)
        Set-Acl -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name\Owners" -AclObject $Owners_ACL

        $New_Owner = Get-Acl "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\$Name"
        $New_Owner = $New_Owner.Owner
        Set-Logging("Current owner is now: $New_Owner")

    }
    Remove_Packages($Packages)
    New-Item -Path "C:\temp" -Name "Completed.txt" -ItemType File

}



Create_Directory

$Packages = (Get-item -path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\Packages\*KB_PLACE_HOLDER*").Name

Change_Ownership($Packages)
