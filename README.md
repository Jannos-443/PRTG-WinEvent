# PRTG-WinEvent
# About

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
   | EXE/Script | PRTG-WinEvent.ps1 |
   | Parameters | -ComputerName %host + at least -LogName or -ProviderName |
   | Security Context | Use Windows credentials of parent device |
   | Scanning Interval | 15 minutes |

## Default global excludes

   | Exclude | Reason |
   | --- | --- |
   | ID = 10016 | MS by design |
   | Provider = Perflib | unnecessary |

## Examples
Example Call: 

`PRTG-WinEvent.ps1 -Computername '%host' -LogName "Application" -TimeAgo 30 -LogLevel "CE" -ExcludeID '^(3025|3018)$'`


![PRTG-WinEvent](media/ok.png)
![PRTG-WinEvent](media/error.png)

excludes
------------------

For more information about regular expressions in PowerShell, visit [Microsoft Docs](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions).

".+" is one or more charakters
".*" is zero or more charakters
