RemovingProfiles.ps1 version 1.1

Author: John Paul Jones, Jr.
Date: 11 July 2019

Synopsis: This PowerShell script leverages CIM cmdlets to facilitate removal of local user profiles on a Windows 7 or higher workstation. 

Usage: Invoke by name in PowerShell or PowerShell ISE. No command-line parameters are accepted. Users have three options for profile removals:
    1) Remove a specific user's profile based on the account name expected to be in the user's local path (e.g., C:\Users\thisaccount);
    2) Remove one or more user profiles based on the LastUseTime property of the CIMInstance (class Win32_UserProfile). User must specify a date range for the LastUseTime property;
    3) Remove temp profiles (based on path name C:\Users\TEMP*)

Dependencies: Use of CIM cmdlets requires installation of PowerShell 3.0 or higher with CIM cmdlets module. User should have administrative rights.

This script has been briefly--but not thoroughly--tested. Use at your own risk.

Improvements to follow:
- Simplify user interface
- Allow a user to back-track or quit from any stage of the script
- Implement an online mode that queries an appropriate domain controller to verify SIDs (useful for domain-migrated environments)
- Allow user-defined exclusions (e.g., remove all profiles *except user X and system accounts*)
- Remote execution of script against a computer that does not have PowerShell 3.0 installed (this one may be tricky, especially because some computers may have PowerShell scripts disabled...)