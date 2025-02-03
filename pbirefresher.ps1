#Purpose of this script is to refresh individual partition in power bi dataset
# Author: Bharath Mohan
# Last Modified: 15-Aug-2024

#Pre-requisites
#use this command to install package in powershell : Install-Module -Name MicrosoftPowerBIMgmt
#Use this command to loginto power bi : Login-PowerBI

#Change these parameters
$startdate = "2025-01-13" #The current date of start.
$monthscount = 4 #No of months in past from start date
$workspaceid = "0ba3d58a-65bf-4b80-8c0f-55a5247c6cff"
$datasetid = "ed662f22-b27d-4c24-86a7-635647779d86"
$tableName="fWeeklySales","fWeeklySales HFB"
$sleepseconds = 100 #sleep time between each check
$maxsleepcycle = 15 #No if cycles to check
$parallelrefresh=4


#Don't change anything beyond this unless you know what you are doing
$url = "groups/$workspaceid/datasets/$datasetid/refreshes"
$startdate = [datetime]::parseexact($startdate, "yyyy-MM-dd", $null)
$iteration_date = $startdate
$monthscountpending=$monthscount

Write-Host "Refreshing $tableName in "$datasetid 

for ($i = 0; $i -lt $monthscount; $i = $i+$parallelrefresh) {
  $objs=@()
  $partname=@()
  $pendingcounter=0
  for ($j=0;($j -lt $parallelrefresh) -and ($j -lt $monthscountpending); $j++)
  {
    $y = $iteration_date.ToString("yyyy")
    $m = $iteration_date.ToString("MM")
    $q = [Math]::ceiling($m / 3)
    $partitionname = $y + "Q" + $q + $m
    $iteration_date = $iteration_date.AddMonths(-1)
    ForEach($tName in $tableName)
    {
    $objs += @{
      table=$tName
      partition=$partitionname
    }
    }
    $partname += $partitionname
    $pendingcounter++
    

  }
  $monthscountpending = $monthscountpending-$pendingcounter
  $payload=@{
    type='full'
    commitMode='transactional'
    objects=$objs
    applyRefreshPolicy='false'
    }
  $payload_final = ConvertTo-Json $payload
  $partinfo=$partname -join ","

  Invoke-PowerBIRestMethod -Url $url -Method Post -Body $payload_final
  Write-Host "Triggering refresh for partitions "$partinfo
  $totalsleep = 0
  $refstart = Get-Date
  Write-Host "Refresh started at "$refstart
  do {
    $res = Invoke-PowerBIRestMethod -Url $url'?$top=1' -Method Get | ConvertFrom-JSON
    $continue = 0
    if ($res.value.status -ne "Completed") {
      Write-Host -NoNewLine "."
      #Write-Host "Sleeping for $sleepseconds seconds"
      $sleepstart = Get-Date
      #Write-Host "Sleep started at $sleepstart. Sleeping for $sleepseconds"
      Start-Sleep -Seconds $sleepseconds
      $sleepend = Get-Date
      #Write-Host "waking up "$sleepend
      $totalsleep += ($sleepend - $sleepstart).Seconds
      if ($totalsleep -le $sleepseconds * $maxsleepcycle) {
        $continue = 1
      }
      else {
      exit
      }
    }
    else {
      $refend = Get-Date
      Write-Host "Refresh Completed at "$refend
    }
  } while ($continue -eq 1)

  Write-Host "-------------------------"

}