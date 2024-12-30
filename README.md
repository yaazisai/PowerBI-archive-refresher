# PowerBI-archive-refresher
For large Power BI semantic models if the base load take more then 5 hours, it is not possible to do it in Power BI Service. This tool allows you to refresh partitions in batches. Use this tool to refresh archive partitions as well
Note: It is only possible to refresh partitions that are at month granularity

This code is written in PowerShell using Power BI cmdlets MicrosoftPowerBIMgmt.Profile

# Parameters to control the execution
- $startdate : processing starts from newest parition and moves back in the direction of oldest partiton. Date in the month of newest partition Eg:"2024-05-03"
- $monthscount : Number of months partitions to process including the latest month partition
- $workspaceid : Workspace id of the semantic model in Power BI service
- $datasetid : Dataset id of of the semantic model in Power BI service
- $tablename : Name of the table in the semantic model that needs to be proccessed
- $sleepseconds: Time in seconds to sleep between each checks to check status of the refresh
- $maxsleepcycle: Max number of sleep cycles to check the status
- $parallelrefresh: Number of partitions to process in parallel
