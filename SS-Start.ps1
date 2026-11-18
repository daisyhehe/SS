<#
    Daisy - SS Tools Downloader  v1.1

    Run from PowerShell (it asks for admin by itself if needed):
        irm https://raw.githubusercontent.com/daisyhehe/SS/main/SS-Start.ps1 | iex

    Works in Windows PowerShell 5.1 and PowerShell 7+.
    The source is plain ASCII on purpose: special characters are built at runtime,
    so the banner never turns into garbage because of file encoding.
#>

$ScriptUrl = 'https://raw.githubusercontent.com/daisyhehe/SS/main/SS-Start.ps1'

# -- Tool groups -------------------------------------------------------------
# Normal URLs are downloaded directly. MediaFire pages and the voidtools
# download page are resolved to a fresh link at runtime (their direct links expire).
$Groups = [ordered]@{
    'Orbdiff' = @(
        'https://github.com/Orbdiff/PrefetchView/releases/download/v1.6.8/pv++.exe'
        'https://github.com/Orbdiff/BAMReveal/releases/download/v1.3.1/BAMReveal.exe'
        'https://github.com/Orbdiff/MFT-HardLink/releases/download/v1.2/HardLink.exe'
        'https://github.com/Orbdiff/Fileless/releases/download/v1.3/fileless.exe'
        'https://github.com/Orbdiff/StringsParser/releases/download/v1.2.1b/stringsparser.1.2.1b.exe'
        'https://github.com/Orbdiff/AmcacheParser/releases/download/v1.0/AmcacheParser.exe'
        'https://github.com/Orbdiff/UserAssistView/releases/download/v1.0/UserAssistView.exe'
        'https://github.com/Orbdiff/USBDetector/releases/download/v1.1/USBDetector.exe'
        'https://github.com/Orbdiff/PFTrace/releases/download/v1.0.1/PFTrace.exe'
    )
    'Tonynoh' = @(
        'https://github.com/MeowTonynoh/MeowClientFucker/releases/download/V1.1/MeowClientFucker.exe'
        'https://github.com/MeowTonynoh/MeowResolver/releases/download/v.1.1/MeowResolver.exe'
        'https://github.com/MeowTonynoh/MeowImportsChecker/releases/download/MeowImportsChecker/MeowImportsChecker.exe'
    )
    'Spokwn' = @(
        'https://github.com/spokwn/JournalTrace/releases/latest/download/JournalTrace.exe'
        'https://github.com/spokwn/KernelLiveDumpTool/releases/download/v1.1/KernelLiveDumpTool.exe'
    )
    'Nirsoft' = @(
        'https://www.nirsoft.net/utils/lastactivityview.zip'
        'https://www.nirsoft.net/utils/previousfilesrecovery-x64.zip'
        'https://www.nirsoft.net/utils/shellbagsview.zip'
    )
    'Generic Tools' = @(
        'https://github.com/winsiderss/si-builds/releases/download/4.0.26245.218/systeminformer-build-canary-setup.exe'
        'https://www.voidtools.com/downloads/'
        'https://github.com/Inkenal/RegistryScanner/releases/download/main/VigilsRegistryScanner.exe'
        'https://github.com/Inkenal/TaskParser/releases/download/main/VigilsTaskParser.exe'
        'https://github.com/horsicq/DIE-engine/releases/download/3.10/die_win64_portable_3.10_x64.zip'
        'https://github.com/deathmarine/Luyten/releases/download/v0.5.4_Rebuilt_with_Latest_depenencies/luyten-0.5.4.exe'
        'https://github.com/zedoonvm1/MarsPixelDumpAnalyzer/releases/download/Dev/MarsPixelDumpAnalyzer.exe'
        'https://mh-nexus.de/downloads/HxDPortableSetup.zip'
        'https://github.com/hasherezade/hollows_hunter/releases/download/v0.4.1.1/hollows_hunter64.exe'
        'https://github.com/Sorted1/StormSS-Fuser-Finder/releases/download/Main/Storm.Fuser.Finder.zip'
        'https://www.mediafire.com/file/lxnu4z9sqzz63lc/file'   # MRCv120.exe
        'https://www.mediafire.com/file/qqhbjhop1zgufsa/file'   # FTK Imager 4.7.3.81
        'https://github.com/praiselily/Siege/releases/download/Scanner/Siege.exe'
        'https://github.com/YasasinTurkiye/FakerDetector/releases/download/v2.12/FakerDetector.exe'
    )
    'Eric Zimmerman' = @(
        'https://download.ericzimmermanstools.com/SrumECmd.zip'             # .NET 4.7.2 build, runs out of the box
        'https://download.ericzimmermanstools.com/MFTECmd.zip'              # .NET 4.7.2 build, runs out of the box
        'https://download.ericzimmermanstools.com/net/TimelineExplorer.zip' # needs .NET 10 Desktop Runtime
        'https://download.ericzimmermanstools.com/net/RegistryExplorer.zip' # needs .NET 10 Desktop Runtime
    )
    'Detect' = @(
        'https://detect.ac/tool/ToolsDownloader++'
    )
    'MSC' = @(
        'https://github.com/piespeas/MSC-Event-Viewer/releases/download/BETA/Event.Viewer.MSC.exe'
    )
}

function Start-SSDownloader {

    # -- Admin check (relaunches itself elevated) -----------------------------
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $isAdmin) {
        Write-Host ''
        Write-Host '  Administrator rights are required. Asking for elevation...' -ForegroundColor Yellow
        if ($PSCommandPath) {
            $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        } else {
            $argList = "-NoProfile -ExecutionPolicy Bypass -Command `"irm '$ScriptUrl' | iex`""
        }
        try {
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList -ErrorAction Stop
        } catch {
            Write-Host '  Elevation was cancelled. Run PowerShell as Administrator and try again.' -ForegroundColor Red
        }
        return
    }

    # -- Console setup --------------------------------------------------------
    $ProgressPreference = 'SilentlyContinue'
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
    try { $Host.UI.RawUI.WindowTitle = 'Daisy - SS Tools Downloader' } catch {}

    # Windows PowerShell 5.1 in the old console does not always enable ANSI colors.
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        try {
            if (-not ('DaisySS.Console' -as [type])) {
                Add-Type -Namespace DaisySS -Name Console -ErrorAction Stop -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int n);
[DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out uint m);
[DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, uint m);
'@
            }
            $h = [DaisySS.Console]::GetStdHandle(-11)
            [uint32]$mode = 0
            if ([DaisySS.Console]::GetConsoleMode($h, [ref]$mode)) {
                [void][DaisySS.Console]::SetConsoleMode($h, ($mode -bor 4))   # ENABLE_VIRTUAL_TERMINAL_PROCESSING
            }
        } catch {}
    }

    # -- Colors (no backtick-e, so it also works in PowerShell 5.1) -----------
    $e      = [char]27
    $R      = "$e[0m"
    $B      = "$e[1m"
    $White  = "$e[38;2;245;245;245m"
    $Dim    = "$e[38;2;130;130;130m"
    $Pink   = "$e[38;2;255;105;180m"
    $Light  = "$e[38;2;255;182;193m"
    $Green  = "$e[38;2;90;220;120m"
    $Red    = "$e[38;2;255;90;90m"
    $Yellow = "$e[38;2;255;210;90m"

    $Line = ([string][char]0x2500) * 64

    # Builds box-drawing glyphs from ASCII placeholders (encoding-proof banner).
    function ConvertTo-Glyphs([string]$Text) {
        $map = @{ '#' = 0x2588; '[' = 0x2554; ']' = 0x2557; '{' = 0x255A; '}' = 0x255D; '=' = 0x2550; '|' = 0x2551 }
        $sb = New-Object System.Text.StringBuilder
        foreach ($c in $Text.ToCharArray()) {
            $k = [string]$c
            if ($map.ContainsKey($k)) { [void]$sb.Append([char]$map[$k]) } else { [void]$sb.Append($c) }
        }
        $sb.ToString()
    }

    function Format-Size([long]$Bytes) {
        if ($Bytes -ge 1GB) { return '{0:N2} GB' -f ($Bytes / 1GB) }
        if ($Bytes -ge 1MB) { return '{0:N1} MB' -f ($Bytes / 1MB) }
        if ($Bytes -ge 1KB) { return '{0:N0} KB' -f ($Bytes / 1KB) }
        return "$Bytes B"
    }

    function Show-Banner {
        Clear-Host
        $logo = @(
            ' ######]  #####] ##]#######]##]   ##]'
            ' ##[==##]##[==##]##|##[====}{##] ##[}'
            ' ##|  ##|#######|##|#######] {####[} '
            ' ##|  ##|##[==##|##|{====##|  {##[}  '
            ' ######[}##|  ##|##|#######|   ##|   '
            ' {=====} {=}  {=}{=}{======}   {=}   '
        )
        $shades = @('255;105;180', '255;120;190', '255;140;200', '255;160;210', '255;175;220', '255;190;228')
        Write-Host ''
        Write-Host "   $Light*      .        *         .      *$R"
        Write-Host ''
        for ($i = 0; $i -lt $logo.Count; $i++) {
            Write-Host ("   $e[38;2;$($shades[$i])m" + (ConvertTo-Glyphs $logo[$i]) + $R)
        }
        Write-Host ''
        Write-Host "   $Light.     *        .       *        .$R"
        Write-Host ''
        Write-Host "   ${Pink}${B}SS Tools Downloader$R  ${Dim}by Daisy  -  v1.1$R"
        Write-Host "   $Dim$Line$R"
        Write-Host ''
    }

    # -- Assemblies + HTTP client ---------------------------------------------
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression -ErrorAction SilentlyContinue
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction SilentlyContinue

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]'Tls12, Tls13'
    } catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    [Net.ServicePointManager]::DefaultConnectionLimit = 32
    [Net.ServicePointManager]::Expect100Continue = $false

    $handler = New-Object System.Net.Http.HttpClientHandler
    $handler.AllowAutoRedirect = $true
    $handler.AutomaticDecompression = [Net.DecompressionMethods]::GZip -bor [Net.DecompressionMethods]::Deflate

    $client = New-Object System.Net.Http.HttpClient($handler)
    $client.Timeout = [TimeSpan]::FromMinutes(10)
    # A normal browser user agent: some hosts (MediaFire, NirSoft) refuse unknown clients.
    [void]$client.DefaultRequestHeaders.TryAddWithoutValidation('User-Agent',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0 Safari/537.36')

    function Get-PageText([string]$Url) {
        $client.GetStringAsync($Url).GetAwaiter().GetResult()
    }

    # Turns pages whose direct links expire into a working download link.
    function Resolve-DownloadUrl([string]$Url) {
        if ($Url -match '^https?://(www\.)?mediafire\.com/file/') {
            $html = Get-PageText $Url
            $m = [regex]::Match($html, 'href="(https?://download\d*\.mediafire\.com/[^"]+)"')
            if ($m.Success) { return $m.Groups[1].Value }
            $m = [regex]::Match($html, 'data-scrambled-url="([^"]+)"')
            if ($m.Success) {
                return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($m.Groups[1].Value))
            }
            throw 'MediaFire download link not found (file removed?)'
        }
        if ($Url -match '^https?://(www\.)?voidtools\.com/downloads/?$') {
            try {
                $m = [regex]::Match((Get-PageText $Url), 'Everything-[\d.]+\.x64-Setup\.exe')
                if ($m.Success) { return "https://www.voidtools.com/$($m.Value)" }
            } catch {}
            return 'https://www.voidtools.com/Everything-1.4.1.1032.x64-Setup.exe'
        }
        return $Url
    }

    function Get-FileNameFor([string]$Url, $Response) {
        $name = $null
        $cd = $Response.Content.Headers.ContentDisposition
        if ($cd) {
            if ($cd.FileNameStar) { $name = $cd.FileNameStar }
            elseif ($cd.FileName) { $name = $cd.FileName }
        }
        if (-not $name -and $Response.RequestMessage.RequestUri) {
            $n = [Uri]::UnescapeDataString([IO.Path]::GetFileName($Response.RequestMessage.RequestUri.AbsolutePath))
            if ([IO.Path]::HasExtension($n)) { $name = $n }
        }
        if (-not $name) {
            $name = [Uri]::UnescapeDataString([IO.Path]::GetFileName(([Uri]$Url).AbsolutePath))
        }
        $name = $name.Trim('"', ' ')
        foreach ($bad in [IO.Path]::GetInvalidFileNameChars()) { $name = $name.Replace([string]$bad, '_') }
        if (-not $name) { $name = 'download' }
        if (-not [IO.Path]::HasExtension($name)) { $name += '.exe' }
        return $name
    }

    function Get-UniquePath([string]$Folder, [string]$Name) {
        $base = [IO.Path]::GetFileNameWithoutExtension($Name)
        $ext  = [IO.Path]::GetExtension($Name)
        $path = Join-Path $Folder $Name
        $i = 2
        while (Test-Path -LiteralPath $path) {
            $path = Join-Path $Folder ('{0}_{1}{2}' -f $base, $i, $ext)
            $i++
        }
        return $path
    }

    # Downloads one tool with a live progress line. Returns 'ok', 'warn' or 'fail'.
    function Invoke-ToolDownload([string]$Url, [string]$Folder, [string]$Prefix) {
        $response = $null; $in = $null; $out = $null; $dest = $null
        $nameWidth = 36

        $pad = {
            param([string]$n)
            if ($n.Length -gt $nameWidth) { $n.Substring(0, $nameWidth - 3) + '...' } else { $n.PadRight($nameWidth) }
        }

        $guess = [Uri]::UnescapeDataString([IO.Path]::GetFileName(([Uri]$Url).AbsolutePath.TrimEnd('/')))
        if ($Url -match 'mediafire\.com/file/([^/]+)') { $guess = "MediaFire ($($Matches[1]))" }
        elseif ($Url -match 'voidtools\.com') { $guess = 'Everything (latest)' }
        Write-Host -NoNewline "`r$Prefix$White$(& $pad $guess)$R  ${Dim}connecting...$R"

        try {
            $realUrl = Resolve-DownloadUrl $Url

            $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $realUrl)
            $u = [Uri]$realUrl
            $req.Headers.Referrer = [Uri]("{0}://{1}/" -f $u.Scheme, $u.Host)

            $response = $client.SendAsync($req, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).GetAwaiter().GetResult()
            if (-not $response.IsSuccessStatusCode) {
                throw "HTTP $([int]$response.StatusCode) $($response.ReasonPhrase)"
            }
            $ctype = "$($response.Content.Headers.ContentType)"
            if ($ctype -like 'text/html*') { throw 'Server returned a web page instead of a file' }

            $name  = Get-FileNameFor $realUrl $response
            $label = "$White$(& $pad $name)$R  "
            $total = $response.Content.Headers.ContentLength
            $dest  = Get-UniquePath $Folder $name

            $in  = $response.Content.ReadAsStreamAsync().GetAwaiter().GetResult()
            $out = New-Object IO.FileStream($dest, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None, 262144)
            $buffer = New-Object byte[] 262144
            [long]$read = 0
            $sw = [Diagnostics.Stopwatch]::StartNew()

            while (($n = $in.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $out.Write($buffer, 0, $n)
                $read += $n
                if ($sw.ElapsedMilliseconds -ge 150) {
                    $sw.Restart()
                    if ($total) { $pct = '{0,3}%' -f [int](($read * 100) / $total) } else { $pct = '   ' }
                    Write-Host -NoNewline "`r$Prefix$label$Pink$pct$R  $Dim$((Format-Size $read).PadRight(10))$R"
                }
            }
            $out.Dispose(); $out = $null
            $in.Dispose();  $in  = $null

            if ($total -and $read -lt $total) { throw "Download incomplete ($(Format-Size $read) of $(Format-Size $total))" }

            if ([IO.Path]::GetExtension($dest) -eq '.zip') {
                $extractDir = Get-UniquePath $Folder ([IO.Path]::GetFileNameWithoutExtension($dest))
                try {
                    [IO.Compression.ZipFile]::ExtractToDirectory($dest, $extractDir)
                    Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue
                    Write-Host "`r$Prefix$label${Green}OK  $R  $Dim$((Format-Size $read) + ' (extracted)')$R      "
                    return 'ok'
                } catch {
                    Write-Host "`r$Prefix$label${Yellow}ZIP $R  ${Dim}saved, but could not extract$R      "
                    return 'warn'
                }
            }

            Write-Host "`r$Prefix$label${Green}OK  $R  $Dim$((Format-Size $read).PadRight(22))$R"
            return 'ok'
        } catch {
            $msg = $_.Exception.Message
            if ($_.Exception.InnerException) { $msg = $_.Exception.InnerException.Message }
            if ($msg.Length -gt 60) { $msg = $msg.Substring(0, 57) + '...' }
            Write-Host "`r$Prefix$White$(& $pad $guess)$R  ${Red}FAIL$R  $Dim$msg$R"
            if ($out) { $out.Dispose() }
            if ($dest -and (Test-Path -LiteralPath $dest)) { Remove-Item -LiteralPath $dest -Force -ErrorAction SilentlyContinue }
            return 'fail'
        } finally {
            if ($in) { $in.Dispose() }
            if ($response) { $response.Dispose() }
        }
    }

    function Read-Answer([string]$Prompt) {
        Write-Host -NoNewline "   $Pink>$R $White$Prompt$R "
        $a = [Console]::ReadLine()
        if ($null -eq $a) { return '' }
        return $a.Trim()
    }

    # -- Menu -----------------------------------------------------------------
    Show-Banner

    $i = 1
    while (Test-Path "C:\SS$i") { $i++ }
    $ssFolder = "C:\SS$i"

    $groupNames = @($Groups.Keys)
    $totalTools = 0
    foreach ($g in $groupNames) { $totalTools += $Groups[$g].Count }

    Write-Host "   ${Dim}Output folder$R   $White$ssFolder$R"
    Write-Host "   ${Dim}Tools$R           $White$totalTools$R ${Dim}in $($groupNames.Count) groups$R"
    Write-Host ''
    for ($g = 0; $g -lt $groupNames.Count; $g++) {
        $num = "[$($g + 1)]".PadRight(5)
        Write-Host ("   $Pink$num$R $White{0}$R $Dim({1})$R" -f $groupNames[$g].PadRight(16), $Groups[$groupNames[$g]].Count)
    }
    Write-Host ''
    Write-Host "   ${Dim}Press Enter to download everything, or type group numbers (e.g. 1,3,5).$R"
    $raw = Read-Answer 'Choice:'

    $selected = New-Object System.Collections.Generic.List[string]
    if ($raw -eq '' -or $raw -match '^(a|all)$') {
        foreach ($g in $groupNames) { $selected.Add($g) }
    } else {
        foreach ($part in ($raw -split '[,\s]+')) {
            if ($part -match '^\d+$') {
                $idx = [int]$part - 1
                if ($idx -ge 0 -and $idx -lt $groupNames.Count -and -not $selected.Contains($groupNames[$idx])) {
                    $selected.Add($groupNames[$idx])
                }
            }
        }
    }

    if ($selected.Count -eq 0) {
        Write-Host ''
        Write-Host "   ${Red}No valid groups selected.$R"
        [void](Read-Answer 'Press Enter to close')
        return
    }

    $toDownload = 0
    foreach ($g in $selected) { $toDownload += $Groups[$g].Count }

    Write-Host ''
    Write-Host "   ${Dim}Selected:$R $White$($selected -join ', ')$R ${Dim}($toDownload tools)$R"
    $confirm = Read-Answer 'Start download? [Y/n]'
    if ($confirm -match '^(n|no)$') {
        Write-Host "   ${Red}Aborted.$R"
        return
    }

    # -- Prepare folder + Defender exclusion ----------------------------------
    Write-Host ''
    $null = New-Item -ItemType Directory -Path $ssFolder -Force
    Write-Host "   ${Green}OK$R  ${Dim}Created$R $White$ssFolder$R"

    if (Get-Command -Name 'Add-MpPreference' -ErrorAction SilentlyContinue) {
        try {
            Add-MpPreference -ExclusionPath $ssFolder -ErrorAction Stop
            Write-Host "   ${Green}OK$R  ${Dim}Defender exclusion added for$R $White$ssFolder$R"
        } catch {
            Write-Host "   ${Yellow}!!$R  ${Dim}Could not add Defender exclusion (tools may get quarantined)$R"
        }
    } else {
        Write-Host "   ${Dim}--  Defender not present, exclusion skipped$R"
    }

    # -- Download -------------------------------------------------------------
    $ok = 0; $warn = 0
    $failed = New-Object System.Collections.Generic.List[string]
    $counter = 0
    $w = "$toDownload".Length
    $timer = [Diagnostics.Stopwatch]::StartNew()

    foreach ($groupName in $selected) {
        $groupDir = Join-Path $ssFolder $groupName
        $null = New-Item -ItemType Directory -Path $groupDir -Force

        Write-Host ''
        Write-Host "   $Pink$B$groupName$R"
        foreach ($url in $Groups[$groupName]) {
            $counter++
            $prefix = "   $Dim$("$counter".PadLeft($w))/$toDownload$R  "
            switch (Invoke-ToolDownload $url $groupDir $prefix) {
                'ok'   { $ok++ }
                'warn' { $warn++ }
                default { $failed.Add("[$groupName] $url") }
            }
        }
    }
    $timer.Stop()
    $client.Dispose()

    # -- Summary --------------------------------------------------------------
    Write-Host ''
    Write-Host "   $Dim$Line$R"
    Write-Host ("   ${Green}Downloaded$R  $White{0} / {1}$R  ${Dim}in {2:N0}s$R" -f ($ok + $warn), $toDownload, $timer.Elapsed.TotalSeconds)
    if ($warn -gt 0) { Write-Host "   ${Yellow}Zip issues$R  $White$warn$R ${Dim}(saved as .zip, extract manually)$R" }
    if ($failed.Count -gt 0) {
        Write-Host "   ${Red}Failed$R      $White$($failed.Count)$R"
        foreach ($f in $failed) { Write-Host "     $Dim$f$R" }
    }
    Write-Host "   $Dim$Line$R"
    Write-Host "   ${Dim}Saved to$R $White$ssFolder$R"
    Write-Host ''

    try { Start-Process explorer.exe -ArgumentList "`"$ssFolder`"" } catch {}
    [void](Read-Answer 'Press Enter to close')
}

Start-SSDownloader
