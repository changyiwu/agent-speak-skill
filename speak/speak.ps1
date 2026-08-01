# speak.ps1 — 快速語音回覆（預設串流：邊生成邊播；備援整檔；再備援 SAPI）
# 用法：
#   pwsh speak.ps1 "要唸的文字"
#   pwsh speak.ps1 -File 講稿.txt
#   pwsh speak.ps1 "文字" -Voice zh-TW-HsiaoChenNeural
#   pwsh speak.ps1 "文字" -Out "D:\專案\回覆.mp3"   # 指定 -Out 時走整檔模式並保留音檔
param(
  [Parameter(Position = 0)][string]$Text,
  [string]$File,
  [ValidatePattern('^[A-Za-z0-9-]+$')]
  [string]$Voice = "zh-TW-YunJheNeural",
  [string]$Out,
  [switch]$NoStream,
  [switch]$Check
)
$ErrorActionPreference = "Stop"

function Get-PythonCommand {
  foreach ($name in @("python", "python3", "py")) {
    $command = Get-Command $name -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($command) {
      return [pscustomobject]@{
        Source = $command.Source
        PrefixArgs = if ($name -eq "py") { @("-3") } else { @() }
      }
    }
  }
  return $null
}

function Test-Assembly([string]$name) {
  try { Add-Type -AssemblyName $name -ErrorAction Stop; return $true }
  catch { return $false }
}

if ($Check) {
  $py = Get-PythonCommand
  $hasEdgeModule = $false
  if ($py) {
    & $py.Source @($py.PrefixArgs) -c "import edge_tts" 2>$null
    $hasEdgeModule = ($LASTEXITCODE -eq 0)
  }
  $hasPlayer = [bool]((Get-Command mpv -ErrorAction SilentlyContinue) -or (Get-Command ffplay -ErrorAction SilentlyContinue))
  $hasEdgeCli = [bool](Get-Command edge-tts -ErrorAction SilentlyContinue)
  $hasSapi = Test-Assembly "System.Speech"
  "STREAM_READY=$([bool]($py -and $hasEdgeModule -and $hasPlayer))"
  "FILE_READY=$hasEdgeCli"
  "SAPI_READY=$hasSapi"
  if (-not $hasEdgeCli -and -not $hasSapi) { exit 1 }
  return
}

if ($File -and $Text) { throw "-Text 與 -File 只能擇一" }
if ($File) { $Text = Get-Content -LiteralPath $File -Raw -Encoding UTF8 }
if (-not $Text) { throw "沒有要唸的文字（positional 或 -File 擇一）" }

function Invoke-SapiFallback([string]$t) {
  Add-Type -AssemblyName System.Speech
  $sp = New-Object System.Speech.Synthesis.SpeechSynthesizer
  try { $sp.Speak($t) }
  finally { $sp.Dispose() }
  "已唸完（SAPI 離線備援，未產生音檔）"
}

# ============ 1. 串流模式（預設）：邊生成邊播放 ============
$py = Get-PythonCommand
$hasPlayer = (Get-Command mpv -ErrorAction SilentlyContinue) -or (Get-Command ffplay -ErrorAction SilentlyContinue)
if (-not $NoStream -and -not $Out -and $py -and $hasPlayer) {
  $streamScript = Join-Path $PSScriptRoot "speak_stream.py"
  $result = $Text | & $py.Source @($py.PrefixArgs) $streamScript - $Voice 2>&1
  if ($LASTEXITCODE -eq 0) {
    "已唸完（Edge-TTS 串流／$Voice）｜$($result -join '｜')"
    return
  }
  Write-Warning "Edge-TTS 串流失敗，改用整檔或 SAPI 備援。"
  # 串流失敗 → 往下走整檔模式
}

# ============ 2. 整檔模式：生成 mp3 後行內播放（無視窗） ============
$edge = Get-Command edge-tts -ErrorAction SilentlyContinue
if (-not $edge) { Invoke-SapiFallback $Text; return }

$keepOutput = [bool]$Out
if (-not $keepOutput) {
  $dir = Join-Path ([IO.Path]::GetTempPath()) "agent-speak"
  New-Item -ItemType Directory -Force $dir | Out-Null
  $Out = Join-Path $dir ("speak_{0}.mp3" -f [guid]::NewGuid().ToString("N"))
}
try {
  $edgeOutput = & $edge.Source --text $Text --voice $Voice --write-media $Out 2>&1
  $edgeExitCode = $LASTEXITCODE
  $validOutput = (Test-Path -LiteralPath $Out) -and ((Get-Item -LiteralPath $Out).Length -gt 0)
  if ($edgeExitCode -ne 0 -or -not $validOutput) {
    Write-Warning "Edge-TTS 整檔生成失敗，改用 SAPI 備援。"
    Invoke-SapiFallback $Text
    return
  }

  $played = $false
  try {
    Add-Type -AssemblyName PresentationCore
    $mp = New-Object System.Windows.Media.MediaPlayer
    try {
      $mp.Volume = 1.0
      $mp.Open([Uri](Resolve-Path -LiteralPath $Out).Path)
      $tries = 0
      while (-not $mp.NaturalDuration.HasTimeSpan -and $tries -lt 100) { Start-Sleep -Milliseconds 100; $tries++ }
      if (-not $mp.NaturalDuration.HasTimeSpan) { throw "無法取得音檔長度" }
      $mp.Play()
      Start-Sleep -Seconds ([math]::Ceiling($mp.NaturalDuration.TimeSpan.TotalSeconds) + 1)
    } finally {
      $mp.Close()
    }
    $played = $true
  } catch {
    try {
      $p = New-Object -ComObject WMPlayer.OCX.7
      try {
        $p.settings.volume = 100
        $p.URL = (Resolve-Path -LiteralPath $Out).Path
        $p.controls.play()
        $deadline = (Get-Date).AddMinutes(5)
        Start-Sleep -Milliseconds 600
        while ($p.playState -in 6, 9, 11) {
          if ((Get-Date) -gt $deadline) { throw "WMPlayer 載入逾時" }
          Start-Sleep -Milliseconds 200
        }
        while ($p.playState -eq 3) {
          if ((Get-Date) -gt $deadline) { throw "WMPlayer 播放逾時" }
          Start-Sleep -Milliseconds 300
        }
      } finally {
        $p.close()
      }
      $played = $true
    } catch { }
  }

  if ($played) {
    if ($keepOutput) { "已唸完（Edge-TTS 整檔／$Voice），音檔：$Out" }
    else { "已唸完（Edge-TTS 整檔／$Voice），暫存音檔已清理" }
  } else {
    Write-Warning "本機播放器失敗，改用 SAPI 備援。"
    Invoke-SapiFallback $Text
  }
} finally {
  if (-not $keepOutput -and (Test-Path -LiteralPath $Out)) {
    Remove-Item -LiteralPath $Out -Force -ErrorAction SilentlyContinue
  }
}
