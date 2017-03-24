function Remove-RgsMember {
<#
.SYNOPSIS
Removes single or multiple users from specific or all response groups.
.Description
Remove-RgsMember uses takes users via the pipeline and removes them from the desired response groups. When specifying the groups, it will remove all users from just those groups. When specifying all groups with the switch, it willgo through all groups they are member of and remove them.  
.PARAMETER User
The user(s) to remove. The user needs to be a SIP address in the form "sip:user@sipdomain". This is required and can utilize the pipeline.
.PARAMETER ResponseGroup
Used to specify individual response groups. Multiple response groups can be specified and should be specified by their 'Name' property. This parameter cannot be used with the AllGroups switch.
.PARAMETER AllGroups
Used to remove the specified users from all response groups they are a member of. This parameter cannot be used with the ResponseGroup parameter.
.EXAMPLE
"sip:user1@sipdomain" | Remove-RgsMember -AllGroups -Verbose
.EXAMPLE
sip:user1@sipdomain,sip:user2@sipdomain | Remove-RgsMember -ResponseGroup RG1
.EXAMPLE
Remove-RgsMember -User sip:user1@sipdomain -ResponseGroup RG1,RG2
.EXAMPLE
Get-Content .\users.txt | Remove-RgsMember -AllGroups -Verbose 
#>

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True,
                    HelpMessage="User(s) to remove (sip:user.sipdomain")]
        [string[]]$User,

        [Parameter(ParameterSetName="specifiedGroups",
                    HelpMessage="One or more RGs, separated by commas")]
        [string[]]$ResponseGroup,

        [Parameter(ParameterSetName="allGroups",
                    HelpMessage="Remove the user(s) from all RGs")]
        [switch]$AllGroups
    )

    BEGIN {
        if ($AllGroups) {
            Write-Verbose -Message "Users will be removed from all response groups"
        }
        else {
            Write-Verbose -Message "Users will be removed from the specified response groups"
        }
    }

    PROCESS {

        #Removing user(s) from all RGs
        if($AllGroups) {
            foreach ($member in $User) {
                Write-Verbose -Message "Removing $member"
                try {
                    $groupsContainingUser = Get-CsRgsAgentGroup | Where-Object {$_.AgentsByUri -contains $member}
                    Write-Verbose -Message "$member is in $($groupsContainingUser.Count) groups"
                }
                catch {
                    Write-Verbose "Unable to get response group information for user "
                }

                if($groupsContainingUser.Count -gt 0) {
                    foreach ($group in $groupsContainingUser) {
                        try{
                            Write-Verbose -Message "Removing $member from $($group.Name)"
                            [void]$group.AgentsByUri.Remove($member)  
                            Set-CsRgsAgentGroup -Instance $group
                        }
                        catch {
                            Write-Verbose -Message "Unable to remove $member from $($group.Name)"
                        }
                    }
                }

                else {
                    Write-Verbose "Not attempting removal as $member was not in any response groups"
                }
   
            }
        }

        #Remove user(s) only from specific RGs
        else {
            foreach ($member in $User) {
                Write-Verbose -Message "Starting removals for $member"
                foreach($group in $ResponseGroup) {
                    try{
                        Write-Verbose -Message "Removing $member from $group"
                        $rg = Get-CsRgsAgentGroup -Name $group
                        [void]$rg.AgentsByUri.Remove($member)
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
