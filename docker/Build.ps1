param(
    [ValidateSet('Debug', 'Release')][string]$Configuration = 'Release',
    [string]$SourceDirectory = 'C:\src',
    [string]$BuildDirectory,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
if (-not $BuildDirectory) {
    $BuildDirectory = Join-Path $SourceDirectory 'out\build\docker-x64'
}
if (-not $OutputDirectory) {
    $OutputDirectory = Join-Path $SourceDirectory "out\docker\$Configuration\amd64"
}
if (-not (Test-Path (Join-Path $SourceDirectory 'CMakeLists.txt'))) {
    throw "Project sources not found in $SourceDirectory. Mount the repository at C:\src."
}

& cmake -S $SourceDirectory -B $BuildDirectory -G 'Visual Studio 17 2022' -A x64 -DWDK_WINVER=0x0A00
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed ($LASTEXITCODE)." }
& cmake --build $BuildDirectory --config $Configuration --parallel
if ($LASTEXITCODE -ne 0) { throw "CMake build failed ($LASTEXITCODE)." }

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
foreach ($artifact in @(
    "sys\$Configuration\com0com.sys",
    "setup\$Configuration\setup.dll",
    "setup\$Configuration\setup.lib",
    "setupc\$Configuration\setupc.exe",
    "setupg\$Configuration\setupg.exe"
)) {
    Copy-Item -LiteralPath (Join-Path $BuildDirectory $artifact) -Destination $OutputDirectory -Force
}
foreach ($file in @('com0com.inf', 'cncport.inf', 'comport.inf', 'ReadMe.txt', 'license.txt')) {
    Copy-Item -LiteralPath (Join-Path $SourceDirectory $file) -Destination $OutputDirectory -Force
}
Write-Host "Unsigned x64 build saved to $OutputDirectory"
