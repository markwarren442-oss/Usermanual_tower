$port = 8080
$root = $PSScriptRoot

# Get the Wi-Fi IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  LOCAL WEB SERVER STARTED!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  On your Phone:" -ForegroundColor Yellow
Write-Host "  http://${ip}:${port}/engineering_manual_template.html" -ForegroundColor Green
Write-Host ""
Write-Host "  Make sure your phone is on the SAME Wi-Fi!" -ForegroundColor Magenta
Write-Host "  Press Ctrl+C to stop the server." -ForegroundColor DarkGray
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$tcpListener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$tcpListener.Start()
Write-Host "Server is listening on port $port..." -ForegroundColor DarkGray

try {
    while ($true) {
        $client = $tcpListener.AcceptTcpClient()
        $stream = $client.GetStream()
        $reader = New-Object System.IO.StreamReader($stream)

        # Read request line
        $requestLine = $reader.ReadLine()
        # Read remaining headers (consume them)
        while ($true) {
            $headerLine = $reader.ReadLine()
            if ([string]::IsNullOrEmpty($headerLine)) { break }
        }

        if ($requestLine -match '^GET\s+(/[^\s]*)\s+HTTP') {
            $urlPath = $Matches[1]
            $urlPath = [System.Uri]::UnescapeDataString($urlPath).TrimStart('/')
            if ($urlPath -eq '' -or $urlPath -eq '/') {
                $urlPath = 'engineering_manual_template.html'
            }
            # Remove query strings
            if ($urlPath.Contains('?')) { $urlPath = $urlPath.Substring(0, $urlPath.IndexOf('?')) }
        } else {
            $urlPath = 'engineering_manual_template.html'
        }

        $filePath = Join-Path $root $urlPath

        if (Test-Path $filePath -PathType Leaf) {
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = switch ($extension) {
                '.html' { 'text/html; charset=utf-8' }
                '.css'  { 'text/css; charset=utf-8' }
                '.js'   { 'application/javascript; charset=utf-8' }
                '.json' { 'application/json; charset=utf-8' }
                '.png'  { 'image/png' }
                '.jpg'  { 'image/jpeg' }
                '.jpeg' { 'image/jpeg' }
                '.gif'  { 'image/gif' }
                '.svg'  { 'image/svg+xml' }
                '.ico'  { 'image/x-icon' }
                default { 'application/octet-stream' }
            }

            $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
            $responseHeader = "HTTP/1.1 200 OK`r`nContent-Type: $contentType`r`nContent-Length: $($fileBytes.Length)`r`nAccess-Control-Allow-Origin: *`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($responseHeader)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($fileBytes, 0, $fileBytes.Length)
            Write-Host "  200 OK  -> $urlPath" -ForegroundColor Green
        } else {
            $body = "404 - File Not Found: $urlPath"
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            $responseHeader = "HTTP/1.1 404 Not Found`r`nContent-Type: text/plain`r`nContent-Length: $($bodyBytes.Length)`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($responseHeader)
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($bodyBytes, 0, $bodyBytes.Length)
            Write-Host "  404     -> $urlPath" -ForegroundColor Red
        }

        $stream.Close()
        $client.Close()
    }
} finally {
    $tcpListener.Stop()
    Write-Host "Server stopped." -ForegroundColor Yellow
}
