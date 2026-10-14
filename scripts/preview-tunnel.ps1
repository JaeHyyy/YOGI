# 집 PC: Flutter 웹(8080) + Cloudflare 임시 터널
# 사용: .\scripts\preview-tunnel.ps1
# 미리 cloudflared 설치: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/

$ErrorActionPreference = "Stop"
$front = Join-Path $PSScriptRoot "..\front" | Resolve-Path

if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
    Write-Host "cloudflared 없음. 설치 후 PATH에 넣고 다시 실행하세요."
    Write-Host "https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
    exit 1
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "flutter 명령을 찾을 수 없습니다. PATH 확인하세요."
    exit 1
}

Write-Host "1) Flutter web-server :8080 시작..."
$flutterProc = Start-Process -FilePath "flutter" `
    -ArgumentList @("run", "-d", "web-server", "--web-hostname", "127.0.0.1", "--web-port", "8080") `
    -WorkingDirectory $front `
    -PassThru `
    -NoNewWindow

Start-Sleep -Seconds 8

Write-Host "2) Cloudflare 터널 시작... (아래 https://....trycloudflare.com 주소를 폰에서 여세요)"
try {
    cloudflared tunnel --url http://127.0.0.1:8080
}
finally {
    if ($flutterProc -and -not $flutterProc.HasExited) {
        Stop-Process -Id $flutterProc.Id -Force -ErrorAction SilentlyContinue
    }
}
