
function Invoke-PsCompile{

    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Position=0, Mandatory=$true, HelpMessage="script")]
        [string]$Path
    )

    $iconFile = "$PSScriptRoot\icons\app.ico"
    $iconFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($iconFile)
    $iconFileParam = "`"/win32icon:$($iconFile)`""

    $FileInfo = Get-Item "$Path"
    $FileBaseName = $FileInfo.Basename 
    $OutputFile = "$PSScriptRoot\$FileBaseName.dll"

    Write-Host "[COMPILER] " -f DarkCyan -n 
    Write-Host "Compiling file `"$Path`" to `"$OutputFile`" "

    $Code = Get-Content "$Path" -Raw -Encoding UTF8
    $Base64Code = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Code))
    $CsCode = Get-Content "$PSScriptRoot\BaseDll.cs" -Raw -Encoding UTF8
    $CsCode = $CsCode.Replace('__BASE64_ENCODED_SCRIPT_CODE__', $Base64Code)

    $type = ('System.Collections.Generic.Dictionary`2') -as "Type"
    $type = $type.MakeGenericType( @( ("System.String" -as "Type"), ("system.string" -as "Type") ) )
    $o = [Activator]::CreateInstance($type)
    $o.Add("CompilerVersion", "v4.0")

    $referenceAssembies = @("System.dll")
    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "System.Management.Automation.dll" } | Select-Object -First 1).Location

    $n = New-Object System.Reflection.AssemblyName("System.Core, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
    [System.AppDomain]::CurrentDomain.Load($n) | Out-Null
    $referenceAssembies += ([System.AppDomain]::CurrentDomain.GetAssemblies() | Where-Object { $_.ManifestModule.Name -ieq "System.Core.dll" } | Select-Object -First 1).Location
    $platform = "anycpu"
    $platform = "x64"
    $manifestParam = ""
    $cop = (New-Object Microsoft.CSharp.CSharpCodeProvider($o))
   
    $cp = New-Object System.CodeDom.Compiler.CompilerParameters($referenceAssembies, $OutputFile)
    $cp.GenerateInMemory = $FALSE
    $cp.GenerateExecutable = $TRUE
    $cp.CompilerOptions = "/platform:$($platform) /target:library $($iconFileParam) $($manifestParam)"
    #$programFrame = Get-Content "$PSScriptRoot\TemperatureCritical.cs" -Raw
    $cr = $cop.CompileAssemblyFromSource($cp, $CsCode)

}


Invoke-PsCompile "$PSScriptRoot\TemperatureCritical.ps1"