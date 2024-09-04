#use this command to install package in powershell : Install-Module -Name MicrosoftPowerBIMgmt
#Use this command to loginto power bi : Login-PowerBI
$startdate = "2024-08-12" #The current date of start
$monthscount = 13 #No of months in past from start date
$workspaceid = "6c8ac021-e124-43de-a995-10db2049221d"
$datasetid = "ecf01287-a27e-4f2f-a406-14cc8207702e"
$sleepseconds = 20 #sleep time between each check
$maxsleepcycle = 10 #No if cycles to check

#Don't change anything beyond this unless you know what you are doing
$url = "groups/$workspaceid/datasets/$datasetid/refreshes"
$startdate = [datetime]::parseexact($startdate, "yyyy-MM-dd", $null)
$iteration_date = $startdate
for ($i = 0; $i -lt $monthscount; $i++) {
  Write-Host "-------------------------"
  $y = $iteration_date.ToString("yyyy")
  #$w=$iteration_date.AddDays(-1 * $iteration_date.DayOfWeek.value__ ).DayOfYear / 7 + 1
  $m = $iteration_date.ToString("MM")
  $q = [Math]::ceiling($m / 3)
  $partitionname = $y + "Q" + $q + $m
  $iteration_date = $iteration_date.AddMonths(-1)

  $body = '{
    "type": "full",
    "commitMode": "transactional",
    "objects": [
      {
        "table": "TestQuery",
        "partition": "'+ $partitionname + '"
      }
    ],
    "applyRefreshPolicy": "false"
  }'

  Invoke-PowerBIRestMethod -Url $url -Method Post -Body $body
  Write-Host "Triggering refresh of partition "$partitionname
  $totalsleep = 0
  do {
    $res = Invoke-PowerBIRestMethod -Url $url'?$top=1' -Method Get | ConvertFrom-JSON
    Write-Host "Status of partition $partitionname :"$res.value.status
    $continue = 0
    if ($res.value.status -ne "Completed") {
      Write-Host "Sleeping for $sleepseconds seconds"
      $sleepstart = Get-Date
      Write-Host "Sleep started at $sleepstart. Sleeping for $sleepseconds"
      Start-Sleep -Seconds $sleepseconds
      $sleepend = Get-Date
      Write-Host "waking up "$sleepend
      $totalsleep += ($sleepend - $sleepstart).Seconds
      if ($totalsleep -le $sleepseconds * $maxsleepcycle) {
        $continue = 1
      }
    }
  } while ($continue -eq 1)

  Write-Host "-------------------------"

}