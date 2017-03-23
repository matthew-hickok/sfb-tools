function Remove-RgsMember {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True,
                    HelpMessage="User(s) to remove (sip:user.sipdomain")]
        [string]$User,

        [Parameter(ParameterSetName="specifiedGroups",
                    HelpMessage="One or more RGs, separated by commas")]
        [string[]]$ResponseGroup,

        [Parameter(ParameterSetName="allGroups",
                    HelpMessage="Remove the user(s) from all RGs")]
        [switch]$AllGroups
    )

    BEGIN {}

    PROCESS {

        #Removing user(s) from all RGs
        if($AllGroups) {
            Write-Verbose -Message "User(s) will be removed from all response groups"
            foreach ($member in $User) {
                Write-Verbose -Message "Removing $member"
                try {
                    $groupsContainingUser = Get-CsRgsAgentGroup | Where-Object {$_.AgentsByUri -contains $member}
                    Write-Verbose -Message "$member is in $($groupsContainingUser.Count) groups"
                }
                catch {
                    Write-Verbose "Unable to get RG information for user "
                }

                if($groupsContainingUser.Count -gt 0) {
                    foreach ($group in $groupsContainingUser) {
                        try{
                            Write-Verbose -Message "Removing $member from $($group.Name)"
                            $group.AgentsByUri.Remove($member)  
                            Set-CsRgsAgentGroup -Instance $group
                        }
                        catch {
                            Write-Verbose -Message "Unable to remove $member from $($group.Name)"
                        }
                    }
                }

                else {
                    Write-Verbose "Not attempting removal as the $member was not in any RGs"
                }
   
            }
        }

        #Remove user(s) only from specific RGs
        else {
            Write-Verbose -Message "User(s) will be removed from specified RGs"
            foreach ($member in $User) {
                Write-Verbose -Message "Starting removals for $member"
                foreach($group in $ResponseGroup) {
                    try{
                        Write-Verbose -Message "Removing $member from $group"
                        $rg = Get-CsRgsAgentGroup -Name $group
                        $rg.AgentsByUri.Remove($member)
                        Set-CsRgsAgentGroup -Instance $rg 
                    }
                    catch {
                        Write-Verbose -Message "Unable to remove $member from $group"
                    }
                }
            }
        }
    }

    END {}

}
