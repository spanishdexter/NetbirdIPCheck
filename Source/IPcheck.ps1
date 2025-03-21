#set script path
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

#------------------------HANDLE TEMP FILES------------------------------------------------------------------

#This goes through the temp folder and removes the empty IPX folders from the IExpress EXE files

$path = $env:TEMP
$pattern = "*IXP0*TMP*"

Get-ChildItem -Path $path -Directory -Force | 
Where-Object {$_.Name -like $pattern} |
Where-Object {$_.GetFileSystemInfos().Count -eq 0} |
Remove-Item -Force
#-----------------------------------------------------------------------------------------------------------

#------------------------GET NETBIRD INFORMATION FROM REGISTRY---------------------------------------------

#your Netbird API token
$APIToken = (Get-ItemProperty "HKLM:\SOFTWARE\NetbirdIPCheck") | Select-Object -ExpandProperty APIToken

#your Netbird server's full URL with port 33073 for API - example https://netbird.mydomain.com:33073
$NetbirdURL = (Get-ItemProperty "HKLM:\SOFTWARE\NetbirdIPCheck") | Select-Object -ExpandProperty NetbirdURL

#if any of these variables are blank the script will exit

if ($APIToken -eq $null) {

#exit script
exit

}

if ($NetbirdURL -eq $null) {

#exit script
exit

}

#-------------------------------------------------------------------------------------------------------------------------------------



#----------------------------------------------------------------------------------------------------------

#------------------------GET ENDPOINT INFORMATION----------------------------------------------------------

$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Token $APIToken"
}

try {
    $response = Invoke-WebRequest -Uri "$NetbirdURL/api/peers" -Method GET -Headers $headers -ContentType "application/json"

    #get data from response into $PeerResponse
    $PeerResponse = $response.Content | ConvertFrom-Json
} catch {
    Write-Error $_.Exception.Message
}

#get current endpoint info
$EndpointInformation = $PeerResponse | Where-Object { $_.hostname -eq $env:COMPUTERNAME}

#get current endpoint public IP address
$connectionIP = $EndpointInformation.connection_ip

#get groups in a list
$EndpointGroups = $EndpointInformation | Select-Object -ExpandProperty groups

#get endpoint group ids
$EndpointGroupIDs = $EndpointGroups.id

#----------------------------------------------------------------------------------------------------------
#-----------------------------GET POSTURE CHECKS----------------------------------------------

$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Token $APIToken"
}

try {
    $response = Invoke-WebRequest -Uri "$NetbirdURL/api/posture-checks" -Method GET -Headers $headers -ContentType "application/json"

    #get data from response into $PostureChecksResponse
    $PostureChecksResponse = $response.Content | ConvertFrom-Json
} catch {
    Write-Error $_.Exception.Message
}

#get posture check labeled "Block Public IPs from VPN"
$BlockVPNPostureCheck = $PostureChecksResponse | Where-Object name -EQ "Block Public IPs from VPN"

#get the posture check ID
$PostureCheckTargetID = $BlockVPNPostureCheck.id

#get posture check IP ranges
$PostureCheckIPRanges = $BlockVPNPostureCheck | Select-Object -ExpandProperty checks | Select-Object -ExpandProperty peer_network_range_check | Select-Object -ExpandProperty ranges

#----------------------------------------------------------------------------------------------------------

#----------------------------GET POLICIES------------------------------------------------------
$headers = @{
    "Accept"        = "application/json"
    "Authorization" = "Token $APIToken"
}

try {
    $response = Invoke-WebRequest -Uri "$NetbirdURL/api/policies" -Method GET -Headers $headers -ContentType "application/json"

    #get data from response into $PoliciesResponse
    $PoliciesResponse = $response.Content | ConvertFrom-Json
} catch {
    Write-Error $_.Exception.Message
}

#Get policies that contain the $PostureCheckTargetID id in source_posture_checks
$BlockVPNPolicies = $PoliciesResponse | Where-Object { $_.source_posture_checks -contains $PostureCheckTargetID }

#get source group ids in $BlockVPNPolicies
$BlockVPNGroups = $BlockVPNPolicies.rules.sources.id

#----------------------------------------------------------------------------------------------

#--------------------------GROUP MATCH CHECK AND ACTION----------------------------------------

#check if endpoint is in any of the Block VPN Groups by comparing group ids

$list1 = $EndpointGroupIDs
$list2 = $BlockVPNGroups

foreach ($item in $list1) {
  if ($list2 -contains $item) {
    $result = "Match Found"
  }
}

#if match if found compare IP addresses from endpoint with those defined in the Block VPN posture check
if ($result -eq "Match Found") {

#get posture check IP ranges and remove CIDR from lines (/32)
$BlockedIPRanges = $PostureCheckIPRanges -replace "/32", ""

#return results - this will be true or false
$AddressMatch = $BlockedIPRanges -contains $connectionIP
    
    #if a public IP match is found stop the process that the posture check would check for
    if ($AddressMatch -eq $true) {

    Write-Host "IP Match was found"

    $processName = "NetbirdPublicIPCheckerPass"
        if (Get-Process -Name $processName -ErrorAction SilentlyContinue) {
            Write-Host "Process '$processName' is running. Stopping process since IP match was found, VPN should be stopped when posture check sees $processName is not running if configured correctly."
            Stop-Process -Name  $processName
            & "C:\Program Files\Netbird\netbird.exe" down
            & "C:\Program Files\Netbird\netbird.exe" up
        }

    } else {
 
    Write-Host "IP Match was not found."
       
    $processName = "NetbirdPublicIPCheckerPass"
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue

        if ($process) {
            Write-Host "$processName is already running."
        } else {
            Write-Host "Process '$processName' is not running. Starting process since IP match was not found, VPN is authorized to launch. VPN should be started when posture check sees $processName is running if configured correctly."
            Start-Process -FilePath "C:\NetBirdIPCheck\NetbirdPublicIPCheckerPass.exe"
            Write-Host "$processName started."
            & "C:\Program Files\Netbird\netbird.exe" down
            & "C:\Program Files\Netbird\netbird.exe" up
        }

    }


}

#----------------------------------------------------------------------------------------------