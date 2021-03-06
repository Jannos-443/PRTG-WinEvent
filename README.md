# PRTG-WinEvent

## Project Owner:

Jannos-443

## Project Details

This Sensor Monitors Windows Eventlog.
You can select a specific LogName or ProviderName.
You can decide which Eventtype counts for example only Error and Critical.
You can exclude IDs, Providers and Messages.

## HOW TO

1. Place `PRTG-WinEvent.ps1` under `C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML`

2. Create new Sensor

   | Settings | Value |
   | --- | --- |
   | EXE/Script Advanced | PRTG-WinEvent.ps1 |
   | Parameters | -ComputerName %host + at least -LogName or -ProviderName |
   | Security Context | Use Windows credentials of parent device |
   | Scanning Interval | 15 minutes |



The script got variables to global exclude events for all devices or parameter to exclude events for special devices.
You can exclude:
 - IDs
 - Provider
 - Messages
 - ID + Provider (both has to match)

## Default global excludes

   | Exclude | Reason |
   | --- | --- |
   | ID= 10016 & Provider= "Microsoft-Windows-DistributedCOM"| MS by design |
   | ID= 1500 & Provider= "SNMP" | Error when SNMP Traps are not configured |
   | Provider = Microsoft-Windows-Perflib | unnecessary |
   


## Examples
Eventlog LogName "Application", LogLevel "CE" (Critical & Error) occured in the last 60 min     

`PRTG-WinEvent.ps1 -Computername '%host' -LogName "Application" -TimeAgo 60 -LogLevel "CE"`

Eventlog LogName "Application" with EventID excludes 

`PRTG-WinEvent.ps1 -Computername '%host' -LogName "Application" -TimeAgo 60 -LogLevel "CE" -ExcludeID '^(3025|3018)$'`

Eventlog Provider "Microsoft-FSLogix-Apps"

`PRTG-WinEvent.ps1 -Computername '%host' -Provider "Microsoft-FSLogix-Apps" -LogLevel "CE" -TimeAgo 60`

Eventlog LogName "System" but exclude Providers "Powershell" and "Veeam Agent"

`PRTG-WinEvent.ps1 -Computername '%host' -LogName "System" -LogLevel "CE" -TimeAgo 60" -ExcludeProvider '^(PowerShell|Veeam Agent)$'`

Eventlog LogName "System" but exclude Provider "Powershell" and Exclude Event IDs "13" and "19" 

`PRTG-WinEvent.ps1 -Computername '%host' -LogName "System" -LogLevel "CE" -TimeAgo 60" -ExcludeProvider '^(PowerShell)$' -ExcludeID '^(13|19)$'`

![PRTG-WinEvent](media/ok.png)
![PRTG-WinEvent](media/error.png)

## FAQ

### The RPC server is unavailable
If you got "The RPC server is unavailable" error, try to enable the Windows Firewall Rule "Remote Event Log Management (RPC)" on the remote Server 

### How to get Provider Names
List all Providers of a Server:
 `Get-WinEvent -ListProvider * | Select Name`
 
List Providers with *perflib* in its Name
 `Get-WinEvent -ListProvider *perflib*`
 
### How to get Log Names
List all Logs of a Server:
 `Get-WinEvent -ListLog *`
 
List Logs with *perf* in its Name
 `Get-WinEvent -ListLog *perf*`

### Required Permission
User has to be member of the "Event Log Readers" Group
![PRTG-WinEvent](media/group.png)

### exclude Syntax
For more information about regular expressions in PowerShell, visit [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions).

".+" is one or more charakters
".*" is zero or more charakters
