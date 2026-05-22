$ErrorActionPreference = "Stop"

$Model = "hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M"
$OllamaUrl = "http://localhost:11434"

function Test-Command {
    param([Parameter(Mandatory = $true)][string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Resolve-OllamaCommand {
    $command = Get-Command "ollama" -ErrorAction SilentlyContinue
    if ($null -ne $command) {
        return $command.Source
    }

    $candidate = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

function Resolve-VSCodeCli {
    $commands = Get-Command "code" -All -ErrorAction SilentlyContinue
    $shim = $commands | Where-Object { $_.Source -like "*.cmd" } | Select-Object -First 1
    if ($null -ne $shim) {
        return $shim.Source
    }

    $candidate = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $candidate) {
        return $candidate
    }

    return $null
}

Write-Host "== GPU =="
if (Test-Command "nvidia-smi") {
    nvidia-smi
}
else {
    Write-Warning "nvidia-smi was not found on PATH."
}

Write-Host ""
Write-Host "== Ollama models =="
$OllamaCommand = Resolve-OllamaCommand
if ($null -eq $OllamaCommand) {
    throw "ollama was not found on PATH."
}

$modelList = & $OllamaCommand list
$modelList

$modelListText = $modelList -join "`n"
if ($modelListText -notmatch [regex]::Escape($Model)) {
    throw "Expected model was not found in ollama list: $Model"
}

Write-Host ""
Write-Host "== Ollama HTTP endpoint =="
$tags = Invoke-RestMethod -Uri "$OllamaUrl/api/tags" -Method Get -TimeoutSec 10
$tags.models | Select-Object name, size, modified_at | Format-Table -AutoSize

Write-Host ""
Write-Host "== Local generation =="
$body = @{
    model = $Model
    prompt = "Reply with exactly: local qwen ready /no_think"
    stream = $false
    options = @{
        temperature = 0.7
        num_predict = 16
    }
} | ConvertTo-Json -Depth 4

$response = Invoke-RestMethod -Uri "$OllamaUrl/api/generate" -Method Post -ContentType "application/json" -Body $body -TimeoutSec 180
$response.response

if ([string]::IsNullOrWhiteSpace($response.response)) {
    throw "The local generation request completed but returned an empty response."
}

Write-Host ""
Write-Host "== VS Code Cline extension =="
$VSCodeCli = Resolve-VSCodeCli
if ($null -ne $VSCodeCli) {
    $extensions = & $VSCodeCli --list-extensions 2>$null
    if ($extensions -contains "saoudrizwan.claude-dev") {
        Write-Host "Cline extension is installed: saoudrizwan.claude-dev"
    }
    else {
        Write-Warning "Cline extension was not found. Install with: code --install-extension saoudrizwan.claude-dev"
    }
}
else {
    Write-Warning "VS Code CLI was not found on PATH."
}
