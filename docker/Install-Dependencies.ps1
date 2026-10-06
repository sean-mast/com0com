param(
    [Parameter(Mandatory = $true)][string]$WdkUrl,
    [Parameter(Mandatory = $true)][string]$NsisVersion
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$downloadDirectory = 'C:\docker\downloads'
New-Item -ItemType Directory -Path $downloadDirectory -Force | Out-Null

function Install-Executable {
    param([string]$Url, [string]$Name, [string[]]$Arguments)
    $installer = Join-Path $downloadDirectory $Name
    Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $installer
    $process = Start-Process -FilePath $installer -ArgumentList $Arguments -WindowStyle Hidden -Wait -PassThru
    if ($process.ExitCode -notin @(0, 3010)) {
        throw "$Name failed with exit code $($process.ExitCode). Installer logs are in $env:TEMP."
    }
    Remove-Item -LiteralPath $installer -Force
}

# The 26100 SDK build matches the WDK 26100.6584 release for VS 2022.
# CMake is supplied by the VS CMake component; the GUI requires C++/CLI and .NET.
Install-Executable -Url 'https://aka.ms/vs/17/release/vs_buildtools.exe' -Name 'vs_buildtools.exe' -Arguments @(
    '--quiet', '--wait', '--norestart', '--nocache', '--installPath', 'C:\BuildTools',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools',
    '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    '--add', 'Microsoft.VisualStudio.Component.VC.CLI.Support',
    '--add', 'Microsoft.VisualStudio.Component.VC.CMake.Project',
    '--add', 'Microsoft.VisualStudio.Component.Windows11SDK.26100',
    '--add', 'Microsoft.Net.Component.4.8.SDK',
    '--add', 'Microsoft.Net.Component.4.8.TargetingPack'
)
Install-Executable -Url $WdkUrl -Name 'wdksetup.exe' -Arguments @('/quiet', '/norestart')
Install-Executable -Url "https://downloads.sourceforge.net/project/nsis/NSIS%203/$NsisVersion/nsis-$NsisVersion-setup.exe" -Name 'nsis-setup.exe' -Arguments @('/S')

# Fail the image build immediately if a silent installer omitted a dependency.
$kitRoot = 'C:\Program Files (x86)\Windows Kits\10'
foreach ($required in @(
    'C:\BuildTools\Common7\Tools\VsDevCmd.bat',
    'C:\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe',
    'C:\Program Files (x86)\NSIS\makensis.exe',
    "$kitRoot\Include\10.0.26100.0\km\ntddk.h",
    "$kitRoot\Lib\10.0.26100.0\km\x64\ntoskrnl.lib",
    "$kitRoot\Lib\wdf\kmdf\x64\1.15\WdfDriverEntry.lib",
    "$kitRoot\bin\10.0.26100.0\x64\mc.exe",
    'C:\Program Files (x86)\Reference Assemblies\Microsoft\Framework\.NETFramework\v4.8\System.Windows.Forms.dll'
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Missing dependency after installation: $required"
    }
}
