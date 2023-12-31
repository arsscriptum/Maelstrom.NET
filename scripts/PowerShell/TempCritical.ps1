
# Define Parameters
[CmdletBinding(SupportsShouldProcess)]
Param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$Job
)


function Get-NotebookFanControlPath{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $expectedLocations=@("${ENV:ProgramFiles(x86)}\NoteBook FanControl", "$ENV:ProgramFiles\NoteBook FanControl")
    $ffFiles=$expectedLocations|%{Join-Path $_ 'nbfc.exe'}
    [String[]]$vPath=@($expectedLocations|?{test-path $_})
    $vPathCount = $vPath.Count
    if($vPathCount){
        return $vPath[0]
    }
    else{
        return $Null
    }
}

function Get-NotebookFanControlExe{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $expectedLocations=@("${ENV:ProgramFiles(x86)}\NoteBook FanControl", "$ENV:ProgramFiles\NoteBook FanControl")
    $ffFiles=$expectedLocations|%{Join-Path $_ 'nbfc.exe'}
    [String[]]$validFiles=@($ffFiles|?{test-path $_})
    $validFilesCount = $validFiles.Count
    if($validFilesCount){
        return $validFiles[0]
    }
    else{
        return $Null
    }
}

function Push-NotebookFanControlPath{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, HelpMessage="exp")]
        [Alias("e")]
        [switch]$Explorer
    )
    $p = Get-NotebookFanControlPath
    pushd $p

    if($Explorer){
        $e = (Get-Command 'explorer.exe').Source
        &"$e" "$p"   
    }
}


function Get-SysStatus{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $NotebookFanControlExe=Get-NotebookFanControlExe
   

    $fs = (InvokeRunNbfc -c "status" -a "-a").Output

    [hashtable]$CurrentStatus = [ordered]@{}
    ForEach($l in $fs){
        $values = $l.split(':')
        if(($values -ne $Null) -And ($values.Count -eq 2)){
            $cfgname = $values[0].Trim()
            $cfgvalue = $values[1].Trim()
            if($CurrentStatus[$cfgname] -ne $Null){
                $cfgname += ' #2'
            }

            $Null = $CurrentStatus.Add($cfgname,$cfgvalue)
        }
    }

    return $CurrentStatus
}
function Get-SysTemperature{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $s = Get-SysStatus

    return $s.'Temperature'
}

function Get-SysServiceStatus{

    [CmdletBinding(SupportsShouldProcess)]
    param()

    $s = Get-SysStatus

    return ($s.'Service enabled' -eq 'True')
}




function Show-CriticalTemperatureNotification{
<#
    .SYNOPSIS
    Display a mesage box with colors to highlight a ERROR message
    .DESCRIPTION
    Display a mesage box with colors to highlight a WARNING message
    .PARAMETER Text
    String to display
#>
    [CmdletBinding(SupportsShouldProcess)]
    param()
    
    $ImportCheck = Test-ExternalGuiAssembliesImported
    $Val = Get-Variable -Name "ExternalGuiAssembliesImported" -Scope 'Global' -ValueOnly -ErrorAction Ignore
    Write-Verbose "External Assemblies Import Check   = $ImportCheck"
    Write-Verbose "Flag ExternalGuiAssembliesImported = $Val"
    if(($ImportCheck -eq $False) -Or ($Val -eq $Null) -Or ($Val -eq $False)){
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System
        Add-Type -AssemblyName System.Xml
        Add-Type -AssemblyName System.Windows
        Set-Variable -Name "ExternalGuiAssembliesImported" -Scope 'Global' -Value $True -ErrorAction Ignore
        Write-Verbose "Setting Flag ExternalGuiAssembliesImported to TRUE"
    }

    $ErrorMsgParams = @{
        Title = "IMPORTANT NOTIFICATION"
        ContentTextForeground = "White"
        ContentBackground = "Red"
        TitleBackground = "Red"
        TitleTextForeground = "Yellow"
        TitleFontWeight = "UltraBold"
        FontFamily = "Verdana"
        TitleFontSize = 20
    }
    $Text = "LAPTOP TEMPERATURE LEVEL IS CRITICAL !!!"
    Show-MessageBox @ErrorMsgParams -Content $Text
}


function Test-ExternalGuiAssembliesImported{
    [CmdletBinding(SupportsShouldProcess)]
    param()
    $AssembliesImported = $True
    try{
        [Windows.Markup.XamlReader] | Get-Member -Static -ErrorAction Stop
        [System.Windows.FontWeights] | Get-Member -Static -ErrorAction Stop
    }catch{
        $AssembliesImported = $False
    }

    return $AssembliesImported
}


$Title = 'TEMPERATURE CRITICAL'
[string]$Temp = 'Critical'
$Message = "Core Temperature Critical" -f $Temp
$Cmd = Get-Command 'Get-SysTemperature'
if($Cmd -ne $Null){
    [string]$Temp = Get-SysTemperature
    $Temp  += ' Celcius'
    $Message = "Core Temperature at {0}" -f $Temp
    $Message = $Message.ToUpper()
}


function Register-Assemblies{
    [CmdletBinding(SupportsShouldProcess)]
    Param()    
    try{
        $Script:WindowsAssemblyReferences | ForEach-Object {
            Write-Verbose "Assembly:  [$PSItem]" 
            Add-Type -AssemblyName $PSItem
        }  
    }catch{
        write-Warning (%_)
    }
  
}

function Get-ScriptDirectory{
    [CmdletBinding(SupportsShouldProcess)]
    Param()    
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    if ($Invocation.PSScriptRoot) {
        $Invocation.PSScriptRoot
    }
    elseif ($Invocation.MyCommand.Path) {
        Split-Path $Invocation.MyCommand.Path
    } else {
        $Invocation.InvocationName.Substring(0,$Invocation.InvocationName.LastIndexOf(""))
    }
}

Function Show-MessageBox{
    <#
        .SYNOPSIS
            Cmdlet to create Message Boxes
        
        .DESCRIPTION
            Cmdlet to create Message Boxes 
        
        .PARAMETER Content
            The popup content
        .PARAMETER Title
            The popup content
        .PARAMETER ButtonType
            
        .PARAMETER CustomButtons
            
        .PARAMETER ContentFontSize
            
        .PARAMETER TitleFontSize
            
        .PARAMETER BorderThickness
            
        .PARAMETER CornerRadius
            
        .PARAMETER ShadowDepth
           
        .PARAMETER BlurRadius
           
        .PARAMETER WindowHost
           
        .PARAMETER Timeout
           
        .PARAMETER OnLoaded
           
        .PARAMETER OnClosed
           
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param
    (
        # The popup Content
        [Parameter(Mandatory=$True)]
        [Object]$Content,

        # The window title
        [Parameter(Mandatory=$false)]
        [string]$Title,

        # The buttons to add
        [Parameter(Mandatory=$false)]
        [ValidateSet('OK','OK-Cancel','Abort-Retry-Ignore','Yes-No-Cancel','Yes-No','Retry-Cancel','Cancel-TryAgain-Continue','None')]
        [array]$ButtonType = 'OK',

        # The buttons to add
        [Parameter(Mandatory=$false)]
        [array]$CustomButtons,

        # Content font size
        [Parameter(Mandatory=$false)]
        [int]$ContentFontSize = 22,

        # Title font size
        [Parameter(Mandatory=$false)]
        [int]$TitleFontSize = 22,

        # BorderThickness
        [Parameter(Mandatory=$false)]
        [int]$BorderThickness = 0,

        # CornerRadius
        [Parameter(Mandatory=$false)]
        [int]$CornerRadius = 8,

        # ShadowDepth
        [Parameter(Mandatory=$false)]
        [int]$ShadowDepth = 3,

        # BlurRadius
        [Parameter(Mandatory=$false)]
        [int]$BlurRadius = 20,

        # WindowHost
        [Parameter(Mandatory=$false)]
        [object]$WindowHost,

        # Timeout in seconds,
        [Parameter(Mandatory=$false)]
        [int]$Timeout,

        # Code for Window Loaded event,
        [Parameter(Mandatory=$false)]
        [scriptblock]$OnLoaded,

        # Code for Window Closed event,
        [Parameter(Mandatory=$false)]
        [scriptblock]$OnClosed

    )




    # Dynamically Populated parameters
    DynamicParam {
        
        # ContentBackground
        $ContentBackground = 'ContentBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentBackground, $RuntimeParameter)
        

        # FontFamily
        $FontFamily = 'FontFamily'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)  
        $arrSet = [System.Drawing.FontFamily]::Families.Name | Select -Skip 1 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($FontFamily, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($FontFamily, $RuntimeParameter)
        $PSBoundParameters.FontFamily = "Verdana"

        # TitleFontWeight
        $TitleFontWeight = 'TitleFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleFontWeight = "UltraBold"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleFontWeight, $RuntimeParameter)

        # ContentFontWeight
        $ContentFontWeight = 'ContentFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentFontWeight = "UltraBold"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentFontWeight, $RuntimeParameter)
        

        # ContentTextForeground
        $ContentTextForeground = 'ContentTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentTextForeground, $RuntimeParameter)

        # TitleTextForeground
        $TitleTextForeground = 'TitleTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleTextForeground, $RuntimeParameter)

        # BorderBrush
        $BorderBrush = 'BorderBrush'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.BorderBrush = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($BorderBrush, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($BorderBrush, $RuntimeParameter)


        # TitleBackground
        $TitleBackground = 'TitleBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleBackground, $RuntimeParameter)

        # ButtonTextForeground
        $ButtonTextForeground = 'ButtonTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonTextForeground, $RuntimeParameter)

        # Sound
        $Sound = 'Sound'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        #$ParameterAttribute.Position = 14
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = (Get-ChildItem "$env:SystemDrive\Windows\Media" -Filter Windows* | Select -ExpandProperty Name).Replace('.wav','')
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($Sound, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($Sound, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }

    Begin{
        Add-Type -AssemblyName System
        Add-Type -AssemblyName System.Drawing
        Add-Type -AssemblyName System.Xml
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName PresentationFramework
        Add-Type -AssemblyName PresentationCore      
    }

    Process{

    


# Define the XAML markup
[XML]$Xaml = @"
<Window 
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        x:Name="Window" Title="" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" Opacity="1">
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border>
                            <Grid Background="{TemplateBinding Background}">
                                <ContentPresenter />
                            </Grid>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Border x:Name="MainBorder" Margin="10" CornerRadius="$CornerRadius" BorderThickness="$BorderThickness" BorderBrush="$($PSBoundParameters.BorderBrush)" Padding="0" >
        <Border.Effect>
            <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="$BlurRadius" ShadowDepth="$ShadowDepth" Opacity="0.6" />
        </Border.Effect>
        <Border.Triggers>
            <EventTrigger RoutedEvent="Window.Loaded">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="$ShadowDepth" Duration="0:0:1" AutoReverse="False" />
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="$BlurRadius" Duration="0:0:1" AutoReverse="False" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Border.Triggers>
        <Grid >
            <Border Name="Mask" CornerRadius="$CornerRadius" Background="$($PSBoundParameters.ContentBackground)" />
            <Grid x:Name="Grid" Background="$($PSBoundParameters.ContentBackground)">
                <Grid.OpacityMask>
                    <VisualBrush Visual="{Binding ElementName=Mask}"/>
                </Grid.OpacityMask>
                <StackPanel Name="StackPanel" >                   
                    <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="10" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$TitleFontSize" Foreground="$($PSBoundParameters.TitleTextForeground)" FontWeight="$($PSBoundParameters.TitleFontWeight)" Background="$($PSBoundParameters.TitleBackground)" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="Center" BorderThickness="0"/>
                    <DockPanel Name="ContentHost" Margin="0,10,0,10"  >
                    </DockPanel>
                    <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center" >
                    </DockPanel>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

[XML]$ButtonXaml = @"
<Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="Auto" Height="30" FontFamily="Segui" FontSize="16" Background="Transparent" Foreground="White" BorderThickness="1" Margin="10" Padding="20,0,20,0" HorizontalAlignment="Right" Cursor="Hand"/>
"@

[XML]$ButtonTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="16" Background="Transparent" Foreground="$($PSBoundParameters.ButtonTextForeground)" Padding="20,5,20,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
"@

[XML]$ContentTextXaml = @"
<TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Text="$Content" Foreground="$($PSBoundParameters.ContentTextForeground)" DockPanel.Dock="Right" HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$ContentFontSize" FontWeight="UltraBold" TextWrapping="Wrap" Height="Auto" MaxWidth="500" MinWidth="50" Padding="10"/>
"@

    
    # Load the window from XAML
    $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))

    # Custom  to add a button
    Function Script:Add-Button {
        Param($Content)
        $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml))
        $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml))
        $ButtonText.Text = "$Content"
        $Button.Content = $ButtonText
        $Button.Add_MouseEnter({
            $This.Content.FontSize = "17"
        })
        $Button.Add_MouseLeave({
            $This.Content.FontSize = "16"
        })
        $Button.Add_Click({
            New-Variable -Name PWSHMessageBoxOutput -Value $($This.Content.Text) -Option ReadOnly -Scope Global -Force
            $Window.Close()
        })
        $Window.FindName('ButtonHost').AddChild($Button)
    }

    # Add buttons
    If ($ButtonType -eq "OK")
    {
        Add-Button -Content "OK"
    }

    If ($ButtonType -eq "OK-Cancel")
    {
        Add-Button -Content "OK"
        Add-Button -Content "Cancel"
    }

    If ($ButtonType -eq "Abort-Retry-Ignore")
    {
        Add-Button -Content "Abort"
        Add-Button -Content "Retry"
        Add-Button -Content "Ignore"
    }

    If ($ButtonType -eq "Yes-No-Cancel")
    {
        Add-Button -Content "Yes"
        Add-Button -Content "No"
        Add-Button -Content "Cancel"
    }

    If ($ButtonType -eq "Yes-No")
    {
        Add-Button -Content "Yes"
        Add-Button -Content "No"
    }

    If ($ButtonType -eq "Retry-Cancel")
    {
        Add-Button -Content "Retry"
        Add-Button -Content "Cancel"
    }

    If ($ButtonType -eq "Cancel-TryAgain-Continue")
    {
        Add-Button -Content "Cancel"
        Add-Button -Content "TryAgain"
        Add-Button -Content "Continue"
    }

    If ($ButtonType -eq "None" -and $CustomButtons)
    {
        Foreach ($CustomButton in $CustomButtons)
        {
            Add-Button -Content "$CustomButton"
        }
    }

    # Remove the title bar if no title is provided
    If ($Title -eq "")
    {
        $TitleBar = $Window.FindName('TitleBar')
        $Window.FindName('StackPanel').Children.Remove($TitleBar)
    }

    # Add the Content
    If ($Content -is [String])
    {
        # Replace double quotes with single to avoid quote issues in strings
        If ($Content -match '"')
        {
            $Content = $Content.Replace('"',"'")
        }
        
        # Use a text box for a string value...
        $ContentTextBox = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ContentTextXaml))
        $Window.FindName('ContentHost').AddChild($ContentTextBox)
    }
    Else
    {
        # ...or add a WPF element as a child
        Try
        {
            $Window.FindName('ContentHost').AddChild($Content) 
        }
        Catch
        {
            $_
        }        
    }

    # Enable window to move when dragged
    $Window.FindName('Grid').Add_MouseLeftButtonDown({
        $Window.DragMove()
    })

    # Activate the window on loading
    If ($OnLoaded)
    {
        $Window.Add_Loaded({
            $This.Activate()
            Invoke-Command $OnLoaded
        })
    }
    Else
    {
        $Window.Add_Loaded({
            $This.Activate()
        })
    }
    

    # Stop the dispatcher timer if exists
    If ($OnClosed)
    {
        $Window.Add_Closed({
            If ($DispatcherTimer)
            {
                $DispatcherTimer.Stop()
            }
            Invoke-Command $OnClosed
        })
    }
    Else
    {
        $Window.Add_Closed({
            If ($DispatcherTimer)
            {
                $DispatcherTimer.Stop()
            }
        })
    }
    

    # If a window host is provided assign it as the owner
    If ($WindowHost)
    {
        $Window.Owner = $WindowHost
        $Window.WindowStartupLocation = "CenterOwner"
    }

    # If a timeout value is provided, use a dispatcher timer to close the window when timeout is reached
    If ($Timeout)
    {
        $Stopwatch = New-object System.Diagnostics.Stopwatch
        $TimerCode = {
            If ($Stopwatch.Elapsed.TotalSeconds -ge $Timeout)
            {
                $Stopwatch.Stop()
                $Window.Close()
            }
        }
        $DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
        $DispatcherTimer.Interval = [TimeSpan]::FromSeconds(1)
        $DispatcherTimer.Add_Tick($TimerCode)
        $Stopwatch.Start()
        $DispatcherTimer.Start()
    }

    # Play a sound
    If ($($PSBoundParameters.Sound))
    {
        $SoundFile = "$env:SystemDrive\Windows\Media\$($PSBoundParameters.Sound).wav"
        $SoundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $SoundFile
        $SoundPlayer.Add_LoadCompleted({
            $This.Play()
            $This.Dispose()
        })
        $SoundPlayer.LoadAsync()
    }

    # Display the window
    $null = $window.Dispatcher.InvokeAsync{$window.ShowDialog()}.Wait()

   }
    
}



$Script:WindowsAssemblyReferences =@()
$Script:WindowsAssemblyReferences += 'System'
$Script:WindowsAssemblyReferences += 'System.Drawing'
$Script:WindowsAssemblyReferences += 'System.Xml'
$Script:WindowsAssemblyReferences += 'System.Windows.Forms'
$Script:WindowsAssemblyReferences += 'PresentationFramework'
$Script:WindowsAssemblyReferences += 'PresentationCore'  

Write-Verbose "Register all current references in WindowsAssemblyReferences"
Register-Assemblies


$MsgBoxTitle = $Title
$MsgBoxMessage = $Message

$Source = "E:\Data\Pictures\ScriptImages\warn_important.jpg"
$Image = New-Object System.Windows.Controls.Image
$Image.Source = $Source
$Image.Height = [System.Drawing.Image]::FromFile($Source).Height
$Image.Width = [System.Drawing.Image]::FromFile($Source).Width

$TextBlock = New-Object System.Windows.Controls.TextBlock
$TextBlock.Text = $MsgBoxMessage
$TextBlock.FontSize = "22"
$TextBlock.HorizontalAlignment = "Center"
         
$StackPanel = New-Object System.Windows.Controls.StackPanel
$StackPanel.AddChild($Image)
$StackPanel.AddChild($TextBlock)
         

$Color = 'Red'



try{
    Show-MessageBox -Content $StackPanel -Title "$MsgBoxTitle" -TitleBackground $Color -TitleTextForeground Black -ContentBackground $Color -TitleFontWeight UltraBold -ContentFontWeight UltraBold
}catch{
    Write-Host "`n[Error] " -nonewline -f DarkRed
    Write-Host " $_`n" -f DarkGray
}

