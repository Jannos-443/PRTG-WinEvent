<#
    .SYNOPSIS
    Monitors Windows Eventlog with the ability to exclude and include.

    .DESCRIPTION
    Using Powershell this script checks the Windows Eventlog from remote Servers.
    You can select a specific LogName or ProviderName.
    You can decide which Eventtype counts for example only Error and Critical.
    You can exclude IDs, Providers and Messages.

    1. Copy this script to the PRTG probe EXE scripts folder (C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML)
    2. create a "EXE/Script Advanced" sensor. Choose this script from the dropdown and set at least:

    + Parameters: -Computername and -LogName or -ProviderName
    + Security Context: Use Windows credentials of parent device
  

    .PARAMETER Computername
    The hostname or IP address of the Windows machine to be checked. Should be set to %host in the PRTG parameter configuration.

    .PARAMETER LogName
    specific LogName for example "Application"
    You have to set -ProviderName or/and -LogName

    .PARAMETER ProviderName
    specific ProviderName for example "Application Error"
    You have to set -ProviderName or/and -LogName
    
    .PARAMETER LogLevel
    - Default = "EC" (Error and Critical)
        LogAlways = A
        Critical = C
        Error = E
        Warning = W
        Informational = I
        Verbose = V
    
    .PARAMETER MaxEvents
    parameter specifies the limit of eventlogs to search in the time interval (TimeAgo)
    - Default is 100

    .PARAMETER TimeAgo (min)
    Minutes to check, for example 30 = the last 30 min.
    - Default is 30

    .PARAMETER ExcludeID
    Regular expression to describe the IDs to Exclude
    - Example: '^(12345|10016)$'
     
    .PARAMETER ExcludeProvider
    Regular expression to describe the Provides to Exclude
    - Example: '^(PowerShell|TestProvider)$'
     
    .PARAMETER ExcludeMessage
    Regular expression to describe the Messages to Exclude
    - Example: '^(Username123)$'
   
    .PARAMETER IncludeID
    Regular expression to describe the IDs to Include
    Include = only this two IDs are found
    - Example: '^(12345|10016)$'
     
    .PARAMETER IncludeProvider
    Regular expression to describe the Provides to Include
    Include = only this two Providers are found
    - Example: '^(WindowsPowershell|TestProvider)$'
     
    .PARAMETER IncludeMessage
    Regular expression to describe the Messages to Include
    Include = only this Messages are found
    - Example: '^(Username123)$'
       
    ####Regular expression example####

      Example: '^(Test123|192.168.3.0)$'

      Example2: '^(192.168.*|10.10.10.1)$' excludes 192.168.12345 and 10.10.10.1

    #https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions?view=powershell-7.1

    .EXAMPLE
    Sample call from PRTG
    PRTG-WinEvent.ps1 -Computername '%host' -LogName "Application" -TimeAgo 30 -LogLevel "CE" -ExcludeID '^(3025|3018)$'
    > Monitors the last 30 min Application Log for Criticals and Errors, excludes IDs 3025 and 3018

    PRTG-WinEvent.ps1 -Computername '%host' -ProviderName "PowerShell" -MaxEvents 10 -TimeAgo 30 -LogLevel "CEW" -ExcludeID '^(30124)$'
    > Monitors the last 30 min Log with source Powershell for Warning, Criticals and Errors, excludes EventID 30124
    
    Author:  Jannos-443
    https://github.com/Jannos-443/PRTG-WinEvent
#>
param(
[string]$Computername = "",
[string]$Username = '',
[string]$Password = '',
[string]$LogName = "",
[string]$ProviderName = "",
[string]$LogLevel = "EC",
[int]$MaxEvents = 100,
[int]$TimeAgo = 30,
[string]$ExcludeID = "",
[string]$ExcludeProvider = "",
[string]$ExcludeMessage = "",
[string]$IncludeID = "",
[string]$IncludeProvider = "",
[string]$IncludeMessage = ""
)

#Catch all unhandled Errors
trap{
    $Output = "line:$($_.InvocationInfo.ScriptLineNumber.ToString()) char:$($_.InvocationInfo.OffsetInLine.ToString()) --- message: $($_.Exception.Message.ToString()) --- line: $($_.InvocationInfo.Line.ToString()) "
    $Output = $Output.Replace("<","")
    $Output = $Output.Replace(">","")
    Write-Output "<prtg>"
    Write-Output "<error>1</error>"
    Write-Output "<text>$Output</text>"
    Write-Output "</prtg>"
    Exit
}

if($Computername -eq "")
    {
    Write-Output "<prtg>"
    Write-Output " <error>1</error>"
    Write-Output " <text>No Computername specified</text>"
    Write-Output "</prtg>"
    Exit
    }

if(($LogName -eq "") -and ($ProviderName -eq ""))
    {
    Write-Output "<prtg>"
    Write-Output " <error>1</error>"
    Write-Output " <text>LogName and/or ProviderName required</text>"
    Write-Output "</prtg>"
    Exit
    }

# Error if there's anything going on
$ErrorActionPreference = "Stop"

#Get Date
$Date = (Get-Date).AddMinutes(-$TimeAgo)

#Check LogName
if($LogName -ne "")
    {
    Get-WinEvent -ListLog $LogName -ComputerName $Computername
    }


#Check ProviderName
if($ProviderName -ne "")
    {
    Get-WinEvent -ListProvider $ProviderName -ComputerName $Computername
    }

#FilterHashTable
if(($ProviderName -ne "") -and ($LogName -ne ""))
    {
    $filter = @{
      LogName="$($LogName)"
      ProviderName="$($ProviderName)"
      StartTime=$Date
        }
    }

elseif($ProviderName -ne "")
    {
    $filter = @{
      ProviderName="$($ProviderName)"
      StartTime=$Date
        }
    }
elseif($LogName -ne "")
    {
    $filter = @{
      LogName="$($LogName)"
      StartTime=$Date
        }
    }

#SuppressHashFilter=@{Level=4}

#Generate Credentials Object, if provided via parameter
try
    {
    if($Username -eq "" -or $Password -eq "") 
        {
        $Credentials = $null
        }
    else 
        {
        $SecPasswd  = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credentials= New-Object System.Management.Automation.PSCredential ($Username, $secpasswd)
        }

    }
 
catch 
    {
    Write-Output "<prtg>"
    Write-Output " <error>1</error>"
    Write-Output " <text>Error Parsing Credentials ($($_.Exception.Message))</text>"
    Write-Output "</prtg>"
    Exit
    }

#Get Events
try{
    if($Credentials -ne $null)
        {
        $Events = Get-WinEvent -MaxEvents $MaxEvents -ComputerName $Computername -FilterHashtable $filter -Credential $Credentials
        }
    
    else
        {
        $Events = Get-WinEvent -MaxEvents $MaxEvents -ComputerName $Computername -FilterHashtable $filter
        }
    }

catch{
    if($_.FullyQualifiedErrorID -eq "NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand")
        {
        $events = $null
        }
    else{
        $Output = "line:$($_.InvocationInfo.ScriptLineNumber.ToString()) char:$($_.InvocationInfo.OffsetInLine.ToString()) --- message: $($_.Exception.Message.ToString()) --- line: $($_.InvocationInfo.Line.ToString()) "
        $Output = $Output.Replace("<","")
        $Output = $Output.Replace(">","")
        Write-Output "<prtg>"
        Write-Output "<error>1</error>"
        Write-Output "<text>$Output</text>"
        Write-Output "</prtg>"
        Exit
        }
    }


#Remove Event Level
if($LogLevel -notmatch "A")
    {
    $Events = $Events | where {$_.Level -ne 0}
    }

if($LogLevel -notmatch "C")
    {
    $Events = $Events | where {$_.Level -ne 1}
    }

if($LogLevel -notmatch "E")
    {
    $Events = $Events | where {$_.Level -ne 2}
    }

if($LogLevel -notmatch "W")
    {
    $Events = $Events | where {$_.Level -ne 3}
    }

if($LogLevel -notmatch "I")
    {
    $Events = $Events | where {$_.Level -ne 4}
    }

if($LogLevel -notmatch "V")
    {
    $Events = $Events | where {$_.Level -ne 5}
    }

#Exclude Provider
if($ExcludeProvider -ne "")
    {
    $Events = $Events | where {$_.ProviderName -notmatch $ExcludeProvider}
    }

#Exclude IDs
if($ExcludeID -ne "")
    {
    $Events = $Events | where {$_.ID -notmatch $ExcludeID}
    }

#Exclude Messages
if($ExcludeMessage -ne "")
    {
    $Events = $Events | where {$_.Message -notmatch $ExcludeMessage}
    }

##Global Excludes
$ExcludeProviderScript = '^(Microsoft-Windows-Perflib)$'
#Perflib = unnecessary

$ExcludeIDScript = '^(123456789)$'

$ExcludeMessageScript = ''

#Exclude ID and Provider has to match
$ExcludeIDwithProvider= @(
       @{ ID = '1500'; Provider = 'SNMP'} #1500 https://social.technet.microsoft.com/forums/windows/en-US/16de5197-3347-4a0d-967e-f5a950f89435/event-1500-snmp
       @{ ID = '10016'; Provider = "Microsoft-Windows-DistributedCOM"} #10016 https://docs.microsoft.com/en-us/troubleshoot/windows-client/application-management/event-10016-logged-when-accessing-dcom#cause
        )

#Exclude Provider
if($ExcludeProviderScript -ne "")
    {
    $Events = $Events | where {$_.ProviderName -notmatch $ExcludeProviderScript}
    }

#Exclude IDs
if($ExcludeIDScript -ne "")
    {
    $Events = $Events | where {$_.ID -notmatch $ExcludeIDScript}
    }

#Exclude Messages
if($ExcludeMessageScript -ne "")
    {
    $Events = $Events | where {$_.Message -notmatch $ExcludeMessageScript}
    }

#Exclude ID+Provider 

foreach($IDplusProvider in $ExcludeIDwithProvider)
    {
    $Events = $Events | where {(($_.ID -ne $IDplusProvider.ID) -or ($_.ProviderName -ne $IDplusProvider.Provider))}
    }
    
##Includes 
#Include IDs
if($IncludeID -ne "")
    {
    $Events = $Events | where {$_.ID -match $IncludeID}
    }

#Include Provider
if($IncludeProvider -ne "")
    {
    $Events = $Events | where {$_.ProviderName -match $IncludeProvider}
    }

#Include Messages
if($IncludeMessage -ne "")
    {
    $Events = $Events | where {$_.Message -match $IncludeMessage}
    }

#Output
$count = $events.count
$text = ""

if($count -ge 1)
    {
    $Last = $Events | select -First 3

    foreach($event in $Last)
        {
        $text += "$($event.TimeCreated) - ID:$($event.ID) Provider:$($event.ProviderName) - $($event.Message)"
        }

    $text = $text.Replace("<","")
    $text = $text.Replace(">","")
    $text = $text.Replace("#","")
    #The number sign (#) is not supported in sensor messages. If a message contains a number sign, the message is clipped at this point - https://www.paessler.com/manuals/prtg/custom_sensors
    }
else
    {
    if($LogName -ne "")
        {
        $text += "Logname: $($LogName) ;"
        }

    if($ProviderName -ne "")
        {
        $text += "ProviderName: $($ProviderName) ;"
        }

    $text += " No Events found in the last $($TimeAgo)min"
    }



$xmlOutput = '<prtg>'
$xmlOutput = $xmlOutput + "<result>
        <channel>Events found</channel>
        <value>$($count)</value>
        <unit>Count</unit>
        <limitmode>1</limitmode>
        <LimitMaxError>0</LimitMaxError>
        </result>"

$xmlOutput = $xmlOutput + "<text>$text</text>"

$xmlOutput = $xmlOutput + "</prtg>"

try
    {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::WriteLine($xmlOutput)
    #https://kb.paessler.com/en/topic/64817-how-can-i-show-special-characters-with-exe-script-sensors
    }

catch
    {
    $xmlOutput
    }
