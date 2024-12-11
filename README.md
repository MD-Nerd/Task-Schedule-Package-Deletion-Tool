# Registry Package Deletion Tool

A set of PowerShell scripts designed to facilitate the management, permission changes, and deletion of Windows Component Based Servicing (CBS) registry keys. The tool consists of two main scripts:

1. **Main.ps1**: Acts as the entry point, handling user input and orchestrating the workflow.
2. **Task_Scheduled_Script.ps1**: Contains the core logic for directory creation, logging, permission changes, and registry key deletions.

---

## **Features**

- **Logging**: Logs every step and action to a file for traceability.
- **Scheduled Task Creation**: Automates the execution of tasks via the Windows Task Scheduler.
- **Registry Key Management**: Handles permission changes and ownership updates for registry keys.
- **Safe Cleanup**: Removes temporary files and resets scripts for future use.
- **Modularity**: Split into two scripts for better organization and reusability.

---

## **Prerequisites**

- **PowerShell**: Requires PowerShell 5.1 or later.
- **Administrator Privileges**: The script must be run as an administrator.
- **Windows Task Scheduler**: Necessary for automating script execution.

---

## **Usage**

1. **Prepare the Scripts**:
   - Place `Main.ps1` and `Task_Scheduled_Script.ps1` in the same directory.
   - Ensure the paths in the scripts (e.g., `C:\temp`) are accessible.

2. **Run the Main Script**:
   - Open PowerShell as an administrator.
   - Navigate to the directory containing `Main.ps1`.
   - Execute the script:
     ```powershell
     .\Main.ps1
     ```

3. **Follow Prompts**:
   - Enter the KB number when prompted (e.g., `KB450765`).
   - The script will handle the rest, including creating scheduled tasks, monitoring execution, and cleaning up after completion.

---

## **File Descriptions**

### **Main.ps1**

The entry point script. It handles user input, sets up the scheduled task, monitors its execution, and performs cleanup.

#### Key Functions:

1. **`Set-Logging`**:
   Logs actions and outputs them to the console.

2. **`Create_ScheduledTask`**:
   Checks for and creates a scheduled task to execute the secondary script.

3. **`Start_ScheduledTask`**:
   Starts the scheduled task.

4. **`Task_Scheduled_Status`**:
   Monitors the status of the scheduled task until completion.

5. **`Refresh_ScheduledTask_Script`**:
   Resets the placeholder in the secondary script for reuse.

6. **`Remove_ScheduledTask`**:
   Deletes the created scheduled task after use.

---

### **Task_Scheduled_Script.ps1**

The core logic script. Handles logging, directory creation, permission changes, and registry key deletions.

#### Key Functions:

1. **`Create_Directory`**:
   Ensures the existence of the `C:\temp` directory.

2. **`Set-Logging`**:
   Logs actions to the file `C:\temp\Package_Deletion.log`.

3. **`Change_Control`**:
   Modifies permissions for a registry key and its `Owners` subkey.

4. **`Remove_Packages`**:
   Deletes specified registry keys and logs the operation.

5. **`Change_Ownership`**:
   Changes the ownership of registry keys, updates permissions, and deletes them.

---

## **Warnings**

1. **Administrative Access**:
   The script requires elevated privileges to modify registry keys.

2. **Irreversible Actions**:
   Once registry keys are deleted, they cannot be recovered unless previously backed up.

3. **Intended Use**:
   This tool should be used with caution and only when necessary. Ensure proper backups are taken before proceeding.

---

## **Example Run**

### **Main.ps1**
```plaintext
Warning: This script is only meant to be used at the discretion of the Microsoft Support Engineer.

Requesting User input.
Please enter the full KB number, for example, KB450765: KB500765

Creating Scheduled Task.
Scheduled Task started.
Waiting for Scheduled task to complete...
Scheduled Task completed.
Refreshing Scheduled Task script for next use.
Scheduled task removed.
```

### **Task_Scheduled_Script.ps1**
```plaintext
Temp Directory 'C:\temp' exists.
Changing permissions to Full Control for the SYSTEM profile for PackageName.
PackageName permissions updated.
Removing PackageName.
PackageName has been removed.
```

---

## **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## **Contributing**

Contributions are welcome! If you encounter issues or have suggestions for improvements:

1. Fork the repository.
2. Create a new branch (`feature/your-feature-name`).
3. Commit your changes (`git commit -m 'Add your feature'`).
4. Push to the branch (`git push origin feature/your-feature-name`).
5. Open a pull request.

---

Happy scripting! 🚀

