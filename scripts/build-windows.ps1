# Build the Windows x64 Release player and stage it for distribution.
#
# Default toolchain: clang-cl (MSVC ABI + Windows SDK) driven by Ninja.
# The generated 68000 translation units are large; clang-cl compiles them in
# well under a minute each. Pass -Msvc to use the Visual Studio generator and
# the MSVC toolset instead (slower on the generated files).
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\build-windows.ps1 `
#       -RomDir C:\path\to\roms
#
# Optional:
#   -SdlDir   <dir containing sdl2-config.cmake>  (default: deps\sdl2\...\cmake)
#   -BuildDir <name>                              (default: build-windows)
#   -Parallel <n>                                 (default: 8)
#   -Msvc                                         use MSVC instead of clang-cl
#   -Test                                         run a headless smoke test
param(
    [Parameter(Mandatory = $true)][string]$RomDir,
    [string]$SdlDir = '',
    [string]$BuildDir = 'build-windows',
    [int]$Parallel = 8,
    [switch]$Msvc,
    [switch]$Test
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RomDir = (Resolve-Path $RomDir).Path
$build = Join-Path $root $BuildDir

if (-not $SdlDir) {
    $candidate = Get-ChildItem (Join-Path $root 'deps\sdl2') -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'cmake' } |
        Where-Object { Test-Path (Join-Path $_ 'sdl2-config.cmake') } |
        Select-Object -First 1
    if (-not $candidate) {
        throw 'SDL2 not found. Unpack the official SDL2 VC development package under deps\sdl2\, or pass -SdlDir.'
    }
    $SdlDir = $candidate
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with the C++ workload was not found.' }
$vsVer = & $vswhere -latest -products * -property installationVersion
$major = ([regex]::Match("$vsVer", '^(\d+)')).Groups[1].Value
$gen = if ($major -eq '18') { 'Visual Studio 18 2026' } elseif ($major -eq '17') { 'Visual Studio 17 2022' } else { "Visual Studio $major" }

$clang = Get-Command clang-cl -ErrorAction SilentlyContinue
if (-not $Msvc -and -not $clang) {
    Write-Warning 'clang-cl was not found; falling back to the MSVC toolset.'
    $Msvc = $true
}

if ($Msvc) {
    Write-Host "== configure ($gen, x64, MSVC) ==" -ForegroundColor Cyan
    & cmake -S $root -B $build -G $gen -A x64 `
        -DLASTBLADE_BUNDLED_SDL2=OFF -DSDL2_DIR="$SdlDir" "-DCMAKE_PREFIX_PATH=$(Split-Path $SdlDir -Parent)" `
        "-DLASTBLADE_ROM_DIR=$RomDir"
    if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }
    Write-Host "== build Release (parallel $Parallel) ==" -ForegroundColor Cyan
    & cmake --build $build --config Release --parallel $Parallel
} else {
    $vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
    Write-Host "== configure (Ninja, clang-cl, x64) ==" -ForegroundColor Cyan
    $cfg = @"
cmake -S "$root" -B "$build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=clang-cl -DCMAKE_CXX_COMPILER=clang-cl -DLASTBLADE_BUNDLED_SDL2=OFF -DSDL2_DIR="$SdlDir" -DCMAKE_PREFIX_PATH="$(Split-Path $SdlDir -Parent)" -DLASTBLADE_ROM_DIR="$RomDir"
"@
    & cmd.exe /c "`"$vcvars`" >nul && $cfg"
    if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }
    Write-Host "== build Release (parallel $Parallel) ==" -ForegroundColor Cyan
    & cmd.exe /c "`"$vcvars`" >nul && cmake --build `"$build`" --parallel $Parallel"
}
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

$exe = @((Join-Path $build 'The Last Blade.exe'), (Join-Path $build 'Release\The Last Blade.exe')) |
    Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $exe) { throw "The Last Blade.exe was not produced under $build" }

if ($Test) {
    Write-Host "== headless smoke test ==" -ForegroundColor Cyan
    $log = Join-Path $build 'smoke.log'
    & cmd.exe /c "`"$exe`" --headless --rom-path `"$RomDir`" --frames 1200 > `"$log`" 2>&1"
    $code = $LASTEXITCODE
    Get-Content $log | Write-Host
    if ($code -ne 0) { throw 'headless smoke test failed' }
}

$dist = Join-Path $root 'dist\windows\TheLastBlade-Windows-x64'
if (Test-Path $dist) { Remove-Item -Recurse -Force $dist }
New-Item -ItemType Directory -Force $dist, (Join-Path $dist 'LICENSES'), (Join-Path $dist 'roms') | Out-Null

Copy-Item $exe $dist
Copy-Item (Join-Path $root 'packaging\windows\README.txt') $dist
Copy-Item (Join-Path $root 'LICENSE') $dist
Copy-Item (Join-Path $root 'THIRD_PARTY_NOTICES.md') $dist
Copy-Item (Join-Path $root 'docs\rom-layout.md') (Join-Path $dist 'ROM-LAYOUT.md')
Copy-Item (Join-Path $root 'docs\compatibility.md') (Join-Path $dist 'COMPATIBILITY.md')
Copy-Item (Join-Path $root 'docs\testing.md') (Join-Path $dist 'TESTING.md')
Copy-Item (Join-Path $root 'neogeorecomp\LICENSE') (Join-Path $dist 'LICENSES\neogeorecomp.txt')
Copy-Item (Join-Path $root 'neogeorecomp\NOTICE') (Join-Path $dist 'LICENSES\neogeorecomp-NOTICE.txt')
Copy-Item (Join-Path $root 'neogeorecomp\LICENSES\*.txt') (Join-Path $dist 'LICENSES')
Copy-Item (Join-Path $root 'packaging\SDL2.txt') (Join-Path $dist 'LICENSES\SDL2.txt')
Set-Content -Path (Join-Path $dist 'roms\PUT-ROM-FILES-HERE.txt') -Encoding ASCII -Value @'
Put your legally obtained ROM files in this folder (or pass --rom-path).

  lastblad.zip -> 234-p1.p1 234-p2.sp2 234-s1.s1 234-m1.m1
                  234-v1.v1 234-v2.v2 234-v3.v3 234-v4.v4
                  234-c1.c1 ... 234-c6.c6
  neogeo.zip  -> sp-s2.sp1 sfix.sfix sm1.sm1 000-lo.lo

The files must be unzipped and directly in this folder. Sizes, CRC32 and
SHA1 are listed in ROM-LAYOUT.md. No ROM data is included in this package.
'@

$sdlDll = Get-ChildItem (Split-Path (Split-Path $SdlDir -Parent) -Parent) -Recurse -Filter SDL2.dll |
    Select-Object -First 1
if (-not $sdlDll) {
    $sdlDll = @((Join-Path $build 'SDL2.dll'), (Join-Path $build 'Release\SDL2.dll')) |
        Where-Object { Test-Path $_ } | ForEach-Object { Get-Item $_ } | Select-Object -First 1
}
if ($sdlDll) { Copy-Item $sdlDll.FullName $dist } else { Write-Warning 'SDL2.dll not found; the player will need it on PATH.' }

# MSVC runtime: clang-cl and MSVC both link the VC runtime when the target
# build machine has no redistributable. Windows 10+ supplies the UCRT.
foreach ($dll in @('msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll')) {
    $src = Join-Path $env:SystemRoot "System32\$dll"
    if (Test-Path $src) { Copy-Item $src $dist }
}

Write-Host "wrote $dist" -ForegroundColor Green
