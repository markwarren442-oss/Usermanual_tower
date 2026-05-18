$file = 'c:\Users\ALJUN RUSTIA\Documents\USERMAUAL TEMPLATE\engineering_manual_template.html'
$lines = Get-Content $file -Encoding UTF8
$styleClose = -1
$headClose = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '</style>') { $styleClose = $i }
    if ($lines[$i] -match '</head>') { $headClose = $i; break }
}
Write-Host "style close at 1-based: $($styleClose+1)"
Write-Host "head close at 1-based: $($headClose+1)"
# Find start of old CSS remnant (line after our new .fade-in block ends at index 345)
$oldStart = -1
for ($i = 345; $i -lt $styleClose; $i++) {
    if ($lines[$i] -match 'flex-direction:\s*column') { $oldStart = $i; break }
}
Write-Host "old remnant start at 1-based: $($oldStart+1)"
