function Remove-RgsMember {

    [CmdletBinding()]
    param (

        [Parameter(Mandatory=$True,
                    ValueFromPipeline=$True,
                    HelpMessage="User to remove (sip:user.sipdomain")]
        [string]$User,

        [string[]]$ResponseGroup,

        [string]$LogLocation,

        [switch]$AllGroups
    )

    BEGIN {}

    PROCESS {

        if($AllGroups) {

            foreach ($member in $User) {
                $groupsContainingUser = Get-CsRgsAgentGroup | Where-Object {$_.AgentsByUri -contains $member}
                foreach ($group in $groupsContainingUser) {    
                    $group.AgentsByUri.Remove($member)  
                    Set-CsRgsAgentGroup -Instance $group  
                }      
            }
        }

        else {
            foreach ($member in $User) {
                foreach($group in $ResponseGroup) {
                    $rg = Get-CsRgsAgentGroup -Name $group
                    $rg.AgentsByUri.Remove($member)
                    Set-CsRgsAgentGroup -Instance $rg 
                }
            }
        }

    }

    END {}

}
