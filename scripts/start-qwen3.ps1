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

function Wait-Ollama {
    param(
        [Parameter(Mandatory = $true)][string]$BaseUrl,
        [int]$TimeoutSeconds = 60
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do {
        try {
            Invoke-RestMethod -Uri "$BaseUrl/api/tags" -Method Get -TimeoutSec 5 | Out-Null
            return $true
        }
        catch {
            Start-Sleep -Seconds 2
        }
    } while ((Get-Date) -lt $deadline)

    return $false
}

Write-Host "== Local Qwen3 14B deployment =="

$OllamaCommand = Resolve-OllamaCommand

if ($null -eq $OllamaCommand) {
    Write-Host "Ollama was not found. Installing with winget..."
    winget install --id Ollama.Ollama --exact --accept-package-agreements --accept-source-agreements

    $OllamaCommand = Resolve-OllamaCommand
    if ($null -eq $OllamaCommand) {
        $candidate = Join-Path $env:LOCALAPPDATA "Programs\Ollama\ollama.exe"
        if (Test-Path $candidate) {
            $env:Path = "$(Split-Path $candidate);$env:Path"
            $OllamaCommand = $candidate
        }
    }
}

if ($null -eq $OllamaCommand) {
    throw "Ollama is still not available. Reopen PowerShell and run this script again."
}

if (-not (Wait-Ollama -BaseUrl $OllamaUrl -TimeoutSeconds 5)) {
    Write-Host "Starting Ollama..."
    Start-Process -FilePath $OllamaCommand -ArgumentList "serve" -WindowStyle Hidden
}

if (-not (Wait-Ollama -BaseUrl $OllamaUrl -TimeoutSeconds 60)) {
    throw "Ollama did not become reachable at $OllamaUrl."
}

Write-Host "Ollama is reachable at $OllamaUrl."
Write-Host "Pulling $Model ..."
& $OllamaCommand pull $Model

Write-Host ""
Write-Host "Model is ready."
Write-Host ""
Write-Host "Cline settings for VS Code:"
Write-Host "  API Provider: Ollama"
Write-Host "  Base URL:     $OllamaUrl"
Write-Host "  Model:        $Model"
Write-Host "  Context:      32768"
Write-Host "  Feature:      Enable Use Compact Prompt"
Write-Host ""
Write-Host "Optional chat test:"
Write-Host "  ollama run $Model"
