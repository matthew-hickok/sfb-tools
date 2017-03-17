if(!(Get-Module SkypeforBusiness) -and !(Get-Module Lync)) {

Write-Host "Install admin tools -- the Lync/SfB module is not installed"

}

else {

    #get public IP
    $desiredEdgeIP = [string]($ip = Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip

    #The string we will search the file for
    $existingValue = '(ConfiguredIPAddress="(\d{1,3}\.?){4}")'

    #What we want the value of the string to be
    $desiredValue = "ConfiguredIPAddress=""$($desiredEdgeIP)"""


    if ($desiredEdgeIP -match '(\d{1,3}\.?){4}') {

        #get topology
        $fileName = 'topology.zip'
        Remove-Item $fileName -Recurse -Force -ErrorAction SilentlyContinue

        #Get topology file
        Export-CsConfiguration -FileName $fileName

        #Export it to new fodler called 'extracted'
        Expand-Archive $fileName -DestinationPath .\extracted

        #Read the xml file
        $topologyFile = Get-Content .\extracted\DocItemSet.xml
    
        #Check to see if the value in the topology matches the current public IP
        if (!$topologyFile.Contains($desiredValue)) {
        
            #Do a find and replace on the IP, replace the XML
            $topologyFile -replace $existingValue,$desiredValue | Set-Content -Path .\extracted\DocItemSet.xml -Force

            #Pack up the 2 topology files into a zip
            Compress-Archive -Path .\extracted\* -DestinationPath new.zip

            #Import it into the CMS
            Import-CsConfiguration -FileName new.zip

            #Enable the new topology
            Enable-CsTopology

        }
        else {
        
            Write-Host "The public IP in the topology matches your current public IP. Congrats."
        
        }


    }

    #Cleanup
    Remove-Item .\extracted,.\topology.zip,.\new.zip -Recurse -Force -ErrorAction SilentlyContinue
}
