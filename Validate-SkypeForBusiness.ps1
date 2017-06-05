$fe_servers = @('sfbfe01.mhickok.me','sfbfe02.mhickok.me','sfbfe03.mhickok.me')
$be_servers = 'sfbbe01.mhickok.me'
$sip_domains = 'mhickok.me'
$fe_pools = 'fepool01.mhickok.me'
$internal_web_services = 'webint-madison'
$external_web_services = 'webext-madison'

$fe_services =  'W3SVC', 'MASTER', 'REPLICA', 'RTCCLSAGT', 'FabricHostSvc', `
                'RTCSRV', 'RTCCAA', 'RTCCAS', 'RTCRGS', 'RTCCPS', 'RTCATS', `
                'RTCIMMCU', 'RTCDATAMCU', 'RTCAVMCU', 'RTCASMCU', 'RTCMEDSRV', `
                'FTA', 'RTCXMPPTGW', 'RTCHA'

$int_dns =  'sip','lyncdiscoverinternal', 'lyncdiscover', 'dialin', 'meet', $internal_web_services
$ext_dns = 'sip', 'lyncdiscover', 'dialin', 'meet', $external_web_services

$synth_tests = @{   'Test-CsAddressBookService' = 'Address Book Service in Reachable';
                    'Test-CsAddressBookWebQuery' = 'Address Book Web Query Successful';
                    'Test-CsAVConference' = 'Conference Established Successfully';
                    'Test-CsIM' = 'IM Sent Successfully'}

$cred = (Get-Credential)

$fe_server = $fe_servers | Get-Random
$fe_session = New-PSSession -ComputerName $fe_server -Credential $cred -Authentication Credssp

$be_session = New-PSSession -ComputerName $be_servers -Credential $cred

function Test-SynthTransaction ($session, $pool, $test) { 
    $com = Invoke-Command -Session $session -ScriptBlock {param($test,$pool)(Invoke-Expression "$test -TargetFqdn `$pool").Result} -ArgumentList $test,$pool
    return $com.Value
}

# services                                                                                                                                                                                                                                                                      
Describe "Skype for Business Front End Health" {
    Context "Front End Services" {
        foreach ($server in $fe_servers) {
            foreach ($service in $fe_services) {
                it "$service on $server is running" {                                                                                                                                                                                       
                    (Get-CsWindowsService -ComputerName $server -Name $service -ErrorAction SilentlyContinue).Status | should be "Running"
                }
            }
        }
    }
}

# dns
$fe_ips = ($fe_servers | Resolve-DnsName).IPAddress
$fe_pools_ips = (Resolve-DnsName $fe_pools).IPAddress

Describe "Internal DNS Records" {
    Context "FE Pool Records" {
        foreach ($ip in $fe_ips) {
            it "$ip is in $fe_pools DNS record" {
                $fe_pools_ips.contains($ip) | should be $true
            }
        }
    }
    Context "Misc Internal Records" {
        foreach ($record in $int_dns) {
            it "$record.$sip_domainss exists" {
                Resolve-DnsName "$record.$sip_domains" -ErrorAction SilentlyContinue | should be $true
            }
        }
    }
    Context "Misc External Records" {
        foreach ($record in $ext_dns) {
            it "$record.$sip_domains exists" {
                Resolve-DnsName "$record.$sip_domains" -Server '8.8.8.8' -ErrorAction SilentlyContinue | should be $true
            }
        }
    }
}

# SQL, db version, ports, database mirroring primary on primary
Describe "SQL Databases" {
    Context "Check Database Versions" {
        $db_results = Test-CsDatabase -ConfiguredDatabases -SqlServerFqdn $be_servers
        foreach ($db in $db_results) {
            It "$($db.DatabaseName) database version is correct" {
                [string]$installed_db_version = "$($db.InstalledVersion.SchemaVersion).$($db.InstalledVersion.SprocVersion).$($db.InstalledVersion.UpgradeVersion)"
                [string]$expected_db_version = "$($db.ExpectedVersion.SchemaVersion).$($db.ExpectedVersion.SprocVersion).$($db.ExpectedVersion.UpgradeVersion)"
                $installed_db_version | should be $expected_db_version
            }
        }
    }
    Context "Check SQL Ports" {
        $sql_ports = @('1433', '5022', '7022')
        foreach ($port in $sql_ports) {
            it "Server is listening on port $port" {
                $port_state = Invoke-Command -Session $be_session -ScriptBlock {param($port)(Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue).State} -ArgumentList $port
                $port_state.Value -contains "Listen" | should be $true
            }   
        }
    }
    Context "Check Mirror Status" {
        $db_state = Get-CsDatabaseMirrorState -PoolFqdn $fe_pools
        foreach ($db in $db_state) {
            it "$($db.DatabaseName) database is on primary" {
                $db.StateOnPrimary -eq "Principal" | should be true
            }    
        }
    }
}

#Synth
Describe "Functional Tests" {
    foreach ($test in $synth_tests.GetEnumerator()) {
        it "$($test.Value)" {
            Test-SynthTransaction -session $fe_session -pool $fe_pools -test "$($test.Name)" | should be "Success"
        }
    }
}
