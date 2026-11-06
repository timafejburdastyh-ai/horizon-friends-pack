[CmdletBinding()]
param(
    [ValidateSet('Install','Launcher','Build','Play')][string]$Action = 'Install',
    [string]$Destination = (Join-Path $env:LOCALAPPDATA 'HorizonFriendsPack'),
    [switch]$Offline,
    [switch]$SkipGameInstall
)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem
$manifest = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'pack.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$utf8 = New-Object System.Text.UTF8Encoding($false)
$Destination = [IO.Path]::GetFullPath($Destination)
$runtimeFile = Join-Path $Destination 'installation.json'

function Write-Utf8([string]$Path, [string]$Content) {
    [IO.File]::WriteAllText($Path, $Content, $utf8)
}

function Get-CheckedPackage($Package) {
    $cache = Join-Path $PSScriptRoot '.cache'
    New-Item -ItemType Directory -Path $cache -Force | Out-Null
    $target = Join-Path $cache $Package.file
    if (-not (Test-Path -LiteralPath $target)) {
        if ($Offline) { throw "Offline package missing: $($Package.file)" }
        if (-not $Package.url.StartsWith('https://github.com/')) { throw 'Unexpected package host' }
        Write-Host "Downloading $($Package.file)"
        $partial = $target + '.part'
        $previousProgress = $ProgressPreference
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -UseBasicParsing -Uri $Package.url -OutFile $partial
        } finally { $ProgressPreference = $previousProgress }
        if ((Get-Item -LiteralPath $partial).Length -ne $Package.size -or
            (Get-FileHash -LiteralPath $partial -Algorithm SHA256).Hash -ne $Package.sha256) {
            throw "Downloaded package failed SHA-256/size verification: $($Package.file)"
        }
        Move-Item -LiteralPath $partial -Destination $target
    }
    if ((Get-Item -LiteralPath $target).Length -ne $Package.size -or
        (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -ne $Package.sha256) {
        throw "Package failed SHA-256/size verification: $($Package.file)"
    }
    return $target
}

function Copy-Checked([string]$Source, [string]$Target, [string]$Hash) {
    if (Test-Path -LiteralPath $Target) {
        if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash -ne $Hash) {
            throw "Existing file differs; it was preserved: $Target"
        }
        return
    }
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    Copy-Item -LiteralPath $Source -Destination $Target
    if ((Get-FileHash -LiteralPath $Target -Algorithm SHA256).Hash -ne $Hash) { throw 'Copy verification failed' }
}

function Install-OrbitalContent([string]$Archive, [string]$Target) {
    $root = [IO.Path]::GetFullPath($Target).TrimEnd('\') + '\'
    $zip = [IO.Compression.ZipFile]::OpenRead($Archive)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName
            if ($name.EndsWith('/')) { continue }
            if ($name -ne 'horizon-mod.toml' -and -not $name.StartsWith('assets/') -and -not $name.StartsWith('data/')) { continue }
            $outPath = [IO.Path]::GetFullPath((Join-Path $Target $name))
            if (-not $outPath.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe archive path' }
            $inputStream = $entry.Open()
            $memory = New-Object IO.MemoryStream
            try { $inputStream.CopyTo($memory); $bytes = $memory.ToArray() }
            finally { $inputStream.Dispose(); $memory.Dispose() }
            if (Test-Path -LiteralPath $outPath) {
                $sha = [Security.Cryptography.SHA256]::Create()
                try {
                    $wanted = [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-','')
                } finally { $sha.Dispose() }
                if ((Get-FileHash -LiteralPath $outPath -Algorithm SHA256).Hash -ne $wanted) { throw "Existing content differs: $outPath" }
            } else {
                New-Item -ItemType Directory -Path (Split-Path -Parent $outPath) -Force | Out-Null
                [IO.File]::WriteAllBytes($outPath, $bytes)
            }
        }
    } finally { $zip.Dispose() }
}

function Choose-Profile {
    for ($i=0; $i -lt $manifest.profiles.Count; $i++) { Write-Host "$($i+1). $($manifest.profiles[$i].name)" }
    $choice = Read-Host 'Choose a mod (1-4), or 0 to cancel'
    if ($choice -eq '0') { return $null }
    if ($choice -notmatch '^[1-4]$') { throw 'Choose 1, 2, 3 or 4' }
    return $manifest.profiles[[int]$choice - 1]
}

if ($Action -ne 'Install') {
    if (-not (Test-Path -LiteralPath $runtimeFile)) { throw 'Run INSTALL.cmd first' }
    $runtime = Get-Content -LiteralPath $runtimeFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $launcher = $runtime.launcher
    if (-not (Test-Path -LiteralPath $launcher)) { throw 'Launcher missing; run INSTALL.cmd again' }
    if ($Action -eq 'Launcher') { & $launcher; exit $LASTEXITCODE }
    $profile = Choose-Profile
    if ($null -eq $profile) { exit 0 }
    if ($Action -eq 'Build') {
        Write-Host 'Building native mod code from its pinned author package. This can take 20-30 minutes or longer.'
        $env:CARGO_BUILD_JOBS = '4'
        & $launcher native-build --instance $profile.slug --profile performance --trust-native-code
    } else {
        & $launcher play --instance $profile.slug
    }
    if ($LASTEXITCODE -ne 0) { throw 'Horizon reported an error. See the message above. Sign in using START-LAUNCHER.cmd before playing.' }
    exit 0
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw 'Windows is required' }
if ([IntPtr]::Size -ne 8) { throw '64-bit PowerShell is required' }
if (Get-Process -Name 'horizon-launcher' -ErrorAction SilentlyContinue) { throw 'Close Horizon Launcher before installing profiles' }
$files = @{}
$files[$manifest.launcher.id] = Get-CheckedPackage $manifest.launcher
foreach ($package in $manifest.packages) { $files[$package.id] = Get-CheckedPackage $package }
$launcherDir = Join-Path $Destination ('launcher-' + $manifest.launcher.version)
$marker = Join-Path $launcherDir '.friends-archive-sha256'
if (-not (Test-Path -LiteralPath $launcherDir)) {
    New-Item -ItemType Directory -Path $launcherDir -Force | Out-Null
    Expand-Archive -LiteralPath $files[$manifest.launcher.id] -DestinationPath $launcherDir
    Write-Utf8 $marker $manifest.launcher.sha256
} elseif (-not (Test-Path -LiteralPath $marker) -or
    (Get-Content -LiteralPath $marker -Raw) -ne $manifest.launcher.sha256) {
    throw 'Destination contains a different launcher installation; choose a new Destination'
}
$launchers = @(Get-ChildItem -LiteralPath $launcherDir -Filter 'horizon-launcher.exe' -Recurse -File)
if ($launchers.Count -ne 1) { throw 'Expected exactly one Horizon launcher' }
$launcher = $launchers[0].FullName
$storePath = Join-Path $env:APPDATA 'horizon-launcher\instances.json'
$before = if (Test-Path -LiteralPath $storePath) { [IO.File]::ReadAllText($storePath) } else { $null }
$store = if ($null -ne $before) { $before | ConvertFrom-Json } else { [pscustomobject]@{ instances = [pscustomobject]@{} } }
if ($null -eq $store.instances) { throw 'Unexpected Horizon instance metadata format' }
$homeRoot = Join-Path $env:APPDATA 'horizon\instances'
foreach ($profile in $manifest.profiles) {
    $homeDir = Join-Path $homeRoot $profile.slug
    $ownership = Join-Path $homeDir '.horizon-friends-profile'
    $present = $store.instances.PSObject.Properties[$profile.slug]
    if ((Test-Path -LiteralPath $homeDir) -or $null -ne $present) {
        if (-not (Test-Path -LiteralPath $ownership) -or (Get-Content -LiteralPath $ownership -Raw) -ne $profile.id) {
            throw "Profile already exists and was preserved: $($profile.slug)"
        }
    }
    New-Item -ItemType Directory -Path $homeDir -Force | Out-Null
    $package = $manifest.packages | Where-Object id -eq $profile.id
    Copy-Checked $files[$profile.id] (Join-Path $homeDir ('horizon-native-mods\' + $profile.id + '.hnmod')) $package.sha256
    $enabled = Join-Path $homeDir 'horizon-mods.txt'
    if (-not (Test-Path -LiteralPath $enabled)) { Write-Utf8 $enabled ("mod." + $profile.id + ":true`n") }
    $shader = $manifest.packages | Where-Object id -eq 'montarc'
    Copy-Checked $files['montarc'] (Join-Path $homeDir ('shaderpacks\' + $shader.file)) $shader.sha256
    if ($profile.id -eq 'orbital') { Install-OrbitalContent $files['orbital'] (Join-Path $homeDir 'horizon-mods\orbital') }
    if ($null -eq $present) {
        $store.instances | Add-Member -MemberType NoteProperty -Name $profile.slug -Value ([pscustomobject]@{name=$profile.name;group='Friends Pack'})
    }
    Write-Utf8 $ownership $profile.id
}
New-Item -ItemType Directory -Path (Split-Path -Parent $storePath) -Force | Out-Null
$current = if (Test-Path -LiteralPath $storePath) { [IO.File]::ReadAllText($storePath) } else { $null }
if ($current -cne $before) { throw 'Launcher settings changed during setup; close the launcher and retry' }
if ($null -ne $before) { Copy-Item -LiteralPath $storePath -Destination ($storePath + '.before-friends-' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssffffZ')) }
$temporaryStore = $storePath + '.friends-' + [Guid]::NewGuid().ToString('N')
Write-Utf8 $temporaryStore ($store | ConvertTo-Json -Depth 30)
Move-Item -LiteralPath $temporaryStore -Destination $storePath -Force
Write-Utf8 $runtimeFile (([ordered]@{launcher=$launcher;pack_version=$manifest.version}) | ConvertTo-Json)
if (-not $SkipGameInstall) {
    & $launcher install $manifest.game_release
    if ($LASTEXITCODE -ne 0) { throw 'Horizon game download failed. Retry INSTALL.cmd; installed profiles were preserved.' }
}
Write-Host 'Installed. Open START-LAUNCHER.cmd, sign in with your own Minecraft account, then BUILD-MOD.cmd and PLAY.cmd.'
