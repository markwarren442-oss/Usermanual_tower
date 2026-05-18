$file = 'c:\Users\ALJUN RUSTIA\Documents\USERMAUAL TEMPLATE\engineering_manual_template.html'
$lines = Get-Content $file -Encoding UTF8
# Keep lines 1-346 (index 0-345) and 927-end (index 926-end)
$keep = @()
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($i -le 345 -or $i -ge 926) {
        $keep += $lines[$i]
    }
}
$keep | Set-Content $file -Encoding UTF8
Write-Host "Done. Removed lines 347-926. New total: $($keep.Count)"
