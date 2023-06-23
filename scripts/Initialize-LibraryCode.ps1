
<#
#̷𝓍   𝓐𝓡𝓢 𝓢𝓒𝓡𝓘𝓟𝓣𝓤𝓜
#̷𝓍   🇵​​​​​🇴​​​​​🇼​​​​​🇪​​​​​🇷​​​​​🇸​​​​​🇭​​​​​🇪​​​​​🇱​​​​​🇱​​​​​ 🇸​​​​​🇨​​​​​🇷​​​​​🇮​​​​​🇵​​​​​🇹​​​​​ 🇧​​​​​🇾​​​​​ 🇬​​​​​🇺​​​​​🇮​​​​​🇱​​​​​🇱​​​​​🇦​​​​​🇺​​​​​🇲​​​​​🇪​​​​​🇵​​​​​🇱​​​​​🇦​​​​​🇳​​​​​🇹​​​​​🇪​​​​​.🇶​​​​​🇨​​​​​@🇬​​​​​🇲​​​​​🇦​​​​​🇮​​​​​🇱​​​​​.🇨​​​​​🇴​​​​​🇲​​​​​
#>



[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Position=0, Mandatory=$true)]
    [string]$ScriptPath
)


function Invoke-SetLibraryCode{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$ScriptPath
    )
    Write-Host "Loading PowerShell script `"$ScriptPath`" ... " -f DarkCyan
    $RootPath = (Resolve-Path "$PSScriptRoot\..").Path
    $BaseDllPath = (Resolve-Path "$RootPath\Template\cs\BaseDll.cs").Path
    $LibraryDllPath = (Resolve-Path "$RootPath\PsWrapperLib\Wrapper.cs").Path
    $DllCode = Get-Content -Path "$BaseDllPath" -Raw -Encoding UTF8
    $Code = Get-Content "$ScriptPath" -Raw -Encoding UTF8
    $Base64Code = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Code))
    
    $DllCode = $DllCode.Replace('__BASE64_ENCODED_SCRIPT_CODE__', $Base64Code)
    
    Write-Host "Generating library source file `"$LibraryDllPath`" ... " -f DarkCyan
    Set-Content -Path "$LibraryDllPath" -Value "$DllCode" -Encoding UTF8
}

Invoke-SetLibraryCode "$ScriptPath"