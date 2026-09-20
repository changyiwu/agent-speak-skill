# speak.ps1 的隔離測試；只執行靜態解析與 -Check，不播放聲音。
param([string]$ProjectRoot)

$ErrorActionPreference = "Stop"
if (-not $ProjectRoot) { $ProjectRoot = Split-Path $PSScriptRoot -Parent }
$scriptPath = Join-Path $ProjectRoot "speak/speak.ps1"
$content = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8

$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseInput(
  $content,
  [ref]$tokens,
  [ref]$errors
) | Out-Null
if ($errors.Count -gt 0) {
  throw "PowerShell 語法解析失敗：$($errors.Message -join '；')"
}

$scriptBlock = [scriptblock]::Create($content)
if ($content -notmatch '\[string\]\$Voice\s*=\s*"zh-TW-HsiaoChenNeural"') {
  throw "PowerShell 預設聲音不是 zh-TW-HsiaoChenNeural"
}
$checkOutput = @(& $scriptBlock -Check)
if (-not ($checkOutput -match '^STREAM_READY=')) { throw "缺少 STREAM_READY 檢查結果" }
if (-not ($checkOutput -match '^FILE_READY=')) { throw "缺少 FILE_READY 檢查結果" }
if (-not ($checkOutput -match '^OFFLINE_READY=')) { throw "缺少 OFFLINE_READY 檢查結果" }

$threw = $false
try {
  & $scriptBlock -Text "測試" -File "不存在.txt"
} catch {
  $threw = ($_.Exception.Message -match "只能擇一")
}
if (-not $threw) { throw "-Text 與 -File 同時使用時應拒絕執行" }

"POWERSHELL_TESTS_PASSED"
