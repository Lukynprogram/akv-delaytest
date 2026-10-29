$Vault = 'kv-kybit-prod'

$env:AZURE_LOGGING_ENABLE_LOG_FILE = 'no'
$env:AZURE_CORE_COLLECT_TELEMETRY  = 'no'

function Now { [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ') }
$Log = Join-Path $HOME ('akv-delaytest-{0}.log' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ'))
function Log([string]$msg) { Write-Host $msg; Add-Content -Path $Log -Value $msg -Encoding utf8 }

$names = az keyvault secret list --vault-name $Vault --query '[].name' -o tsv
if ($LASTEXITCODE -ne 0) { Log "$(Now)  LIST FAIL  exit=$LASTEXITCODE"; return }

$ok = 0; $fail = 0
foreach ($n in $names) {
    $n = "$n".Trim()
    if (-not $n) { continue }
    $ts  = Now
    $out = az keyvault secret show --vault-name $Vault --name $n --query name -o tsv 2>&1
    if ($LASTEXITCODE -eq 0) {
        $ok++;   Log "$ts  GET   $n"
    } else {
        $last = $out | ForEach-Object { "$_".Trim() } | Where-Object { $_ } | Select-Object -Last 1
        $fail++; Log "$ts  FAIL  $n  $last"
    }
}
Remove-Variable out -ErrorAction SilentlyContinue

Log "KONEC $(Now)  SecretGet OK=$ok FAIL=$fail  ground-truth: $Log"
