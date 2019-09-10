<# // This script is intended to facilitate easy removal of old user profiles
// Intended options:
// ----Remove profile by username
// ----Remove all profiles by date (last modified before a specific date,
//     within a date range, or after a specific date).
// ----Remove all "TEMP" profiles
#>


# display main menu and prompt for user selection
function Get-MainMenu {

    $ValidSelection = $false

    # check validity of selection.
    while (!$ValidSelection) {
        # advertise options
        Write-Host "`nOption 1: Remove a specified user profile by username"
        Write-Host "`nOption 2: Remove one or more user profiles by date"
        Write-Host "`nOption 3: Remove TEMP profiles"

        # request selection from user
        $RemovalType = Read-Host -Prompt "`nEnter the number of your selection. Enter 'q' to quit"

        # compare with defined option strings "1", "2"
        if ( !($RemovalType.CompareTo("1")) -or !($RemovalType.CompareTo("2")) -or !($RemovalType.CompareTo("3"))) {
            $ValidSelection = $true
            return $RemovalType
        }
    
        # compare with defined strings "q", "Q" to quit script
        if ( !( ($RemovalType.ToLower()).CompareTo("q") )) {
            Write-Host "`nExiting script per user selection."
            Exit
        }
    }
}

# prompt user and return a date object to be used for profile removals
function Make-ValidDate {

    $UserMonth = Read-Host -prompt "Enter numeric month (or 'x' to cancel)"   
    if ($UserMonth -eq "x") {
        return (Get-Date -date 01/01/1000)
    }   
    $UserDay = Read-Host -prompt "Enter numeric day (or 'x' to cancel)"
    if ($UserMonth -eq "x") {
        return (Get-Date -date 01/01/1000)
    }            
    $UserYear = Read-Host -prompt "Enter year (or 'x' to cancel)"
    if ($UserMonth -eq "x") {
        return (Get-Date -date 01/01/1000)
    }

    # attempt to cast strings as ints
    $NumericMonth = $UserMonth -as [int]
    $NumericDay = $UserDay -as [int]
    $NumericYear = $UserYear -as [int]

    # non-integer provided
    if (!$NumericMonth -or !$NumericDay -or !$NumericYear) {
        Write-Host "`nMonth, day, and year must be integral values."
        return (Get-Date -date 01/01/1050)
    }
        
    # check for plausible year
    if ( ($NumericYear -lt 2000) -or ($NumericYear -gt (get-date -format yyyy) ) ) {
        return (Get-Date -date 01/01/1050)
    }

    $IsLeap = $False

    if ( ($NumericYear % 4 -eq 0) -and ($NumericYear % 100 -ne 0) ) {
        $IsLeap = $True
    }


    # check for valid month
    if ( ($NumericMonth -lt 1) -or ($NumericMonth -gt 12)) {
        return (Get-Date -date 01/01/1050)
    }

    # check for plausible day
    if ( ($NumericDay -lt 1) -or ($NumericDay -gt 31) ) {
        return (Get-Date -date 01/01/1050)
    }

    $MaxDay = 0

    # validate day given month selection
    if ( ($NumericMonth -eq 1) -or ($NumericMonth -eq 3) -or ($NumericMonth -eq 5) -or
         ($NumericMonth -eq 7) -or ($NumericMonth -eq 8) -or ($NumericMonth -eq 10) -or
         ($NumericMonth -eq 12) ) {
         $MaxDay = 31
    }
    if ( ($NumericMonth -eq 4) -or ($NumericMonth -eq 6) -or
         ($NumericMonth -eq 9) -or ($NumericMonth -eq 11) ) {
         $MaxDay = 30
    }
    if ( ($NumericMonth -eq 2) ) {
        if ($IsLeap) {
            $MaxDay = 29
        }
        else {
            $MaxDay = 28
        }
    }

    if ($NumericDay -gt $MaxDay) {
        return (Get-Date -date 01/01/1050)
    }

    # return date
    return (Get-Date -date $NumericMonth/$NumericDay/$NumericYear)
}

# remove temp profiles
function Remove-TempProfiles {

    # advise if no temp profiles found
    $TempProfiles = Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.LocalPath -like "C:\Users\TEMP*" }
    if (!($TempProfiles)) {
        Write-Host "`n No temp profiles found!"
    } else {
        $TempProfiles | Foreach-Object { Write-Host "Removing $($_.LocalPath)"; Remove-CimInstance -Class Win32_UserProfile $_ }
    }
}

# remove user profile by name
function Remove-UserByName {
    Write-Host "`nYou have chosen to remove a user profile by username."
    $SelectedUser = Read-Host -prompt "Enter the username whose profile you would like to delete"
    $SelectedDomain = Read-Host -prompt "Enter the domain of the user profile"

    # search for specified user profile
    $SelectedProfile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object { $_.LocalPath -eq "C:\Users\$($SelectedUser)" }
    
    # warn if no match found
    if(! ($SelectedProfile))  { 
        Write-Host "Did not find profile under username $($SelectedUser)"
        
        # try to match to username.domain
        $SelectedProfile = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {$_.LocalPath -eq "C:\Users\$($SelectedUser).$($SelectedDomain)" }
        
        if (! ($SelectedProfile)) {
            Write-Host "Did not find profile matching path $($SelectedUser).$($SelectedDomain)"
            return
        }
        else {
            Write-Host "Matched to profile $($SelectedUser).$($SelectedDomain)"
        }
    }
    
    # remove selected profile
    Remove-CimInstance -InputObject $SelectedProfile -WhatIf
    
}

# remove user profile by date
function Remove-UserByDate {
    Write-Host "`nYou have chosen to remove one or more user profiles by date."
    
    # display menu options
    Write-Host "You may choose to remove profiles matching the following criteria:"
    Write-Host "Option 1: Remove all profiles older than date MM/dd/yyyy;"
    Write-Host "Option 2: Remove all profiles newer than date MM/dd/yyyy;"
    Write-Host "Option 3: Remove all profiles between date MM/dd/yyyy and date MM/dd/yyyy."
    $DateMethod = Read-Host -prompt "`nSelect removal type [1/2/3] or press 'x' to cancel"

    # initialize with "dummy" values
    $StartDate = Get-Date -date 01/01/1900
    $EndDate = (Get-Date).AddDays(1)

    switch -exact ($DateMethod) {
        # select start date 
        "1" { Write-Host "`nYou have chosen to remove all profiles modified before a specified date."
              $EndDate = Make-ValidDate; Break }
        "2" { Write-Host "`nYou have chosen to remove all profiles modified since a specified date."
              $StartDate = Make-ValidDate; Break }
        "3" { Write-Host "`nYou have chosen to remove all profiles modified within a specified date range."
              Write-Host "Start date of range:"
              $StartDate = Make-ValidDate
              Write-Host "End date of range:"
              $EndDate = Make-ValidDate; Break }
        "x" { Write-Host "`nYou have chosen to cancel."
              Return; Break }
        default { Write-Host "`nNo valid selection made." }
    }

    # test against control value 01/01/1050 - invalid date provided
    if (!$StartDate.CompareTo((get-date -date 01/01/1050)) -or !$EndDate.CompareTo((get-date -date 01/01/1050))) {
        Write-Host "Invalid date entry."
        return
    }

    # test against control value 01/01/1000 - user decided to cancel
    if (!$StartDate.CompareTo((get-date -date 01/01/1000)) -or !$EndDate.CompareTo((get-date -date 01/01/1000))) {
        Write-Host "User terminated deletion by date."
        return
    }

    # remove profiles with last modification date between $StartDate and $EndDate

    Get-CimInstance Win32_UserProfile | Foreach-Object {

        # verify date range
        if ( ($_.LastUseTime -lt $EndDate) -and ($_.LastUseTime -gt $StartDate) ) {

            # remove account if not owned by system service
             if ($_.Special -ne $True ) {
                Write-Host "`n Deleting profile $($_.LocalPath) with SID $($_.SID)"
                Remove-CimInstance $_ 
             }

        }

    }  

}

# display opening message
Write-Host "This tool is intended to remove local profiles for Windows users."

$QuitScript = $false

while (!($QuitScript)) {

    # prompt for selection from main menu
    $UserChoice = Get-MainMenu

    Write-Host "User choice was $UserChoice`n"

    # remove profile by username
    if ( !($UserChoice.compareTo("1")) ) {
        Remove-UserByName
    }

    # remove profile by date or date range
    if ( !($UserChoice.CompareTo("2")) ) {
        Remove-UserByDate
    }

    # remove temp profiles
    if ( !($UserChoice.CompareTo("3")) ) {
        Remove-TempProfiles
    }

    # prompt for continuation
    $ContinueScript = Read-Host -prompt "Return to main menu? Press 'y' to continue"

    if ( $ContinueScript.toLower().compareTo("y") ) {
        $QuitScript = $true
    }

}


Exit