# Local Qwen3 14B + Cline on Windows

This repo documents and automates a local coding-assistant setup for:

- Windows + NVIDIA GPU
- VS Code + Cline
- Ollama
- `Qwen/Qwen3-14B-GGUF` served as `hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M`

## Hardware Found

The selected model quant is `Q4_K_M`, about 9 GB on the official Hugging Face model card. This leaves much more headroom than `Q8_0`, which is listed around 15.7 GB and is too tight for a 16 GB GPU once runtime and context overhead are included.

## Model Naming Note

The requested setup says "Qwen3-Coder 14B". Qwen's official Qwen3-Coder collection currently lists Coder models such as `Qwen/Qwen3-Coder-480B-A35B-Instruct` and `Qwen/Qwen3-Coder-30B-A3B-Instruct`.

For this 16 GB local GPU setup, this repo uses the official 14B GGUF model:

```text
hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M
```

That is the official Qwen3 14B GGUF, not a separately branded Qwen3-Coder 14B checkpoint.

## Quick Deploy

Run this from the repo root in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\start-qwen3.ps1
```

The script will:

1. Install Ollama with `winget` if `ollama` is missing.
2. Ensure Ollama is running on `http://localhost:11434`.
3. Pull `hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M`.
4. Print the exact Cline settings to use in VS Code.

## Manual Commands

Install Ollama if needed:

```powershell
winget install --id Ollama.Ollama --exact
```

Pull and run the model:

```powershell
ollama pull hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M
ollama run hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M
```

Install Cline in VS Code:

```powershell
code --install-extension saoudrizwan.claude-dev
```

If `code` resolves to `Code.exe` and reports `bad option: --install-extension`, use the VS Code CLI shim directly:

```powershell
& "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd" --install-extension saoudrizwan.claude-dev
```

## Cline Configuration

Open VS Code, then open Cline settings and configure:

- API Provider: `Ollama`
- Base URL: `http://localhost:11434`
- Model: `hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M`
- Context Window: `32768`
- Feature setting: enable `Use Compact Prompt`

Cline configuration is intentionally documented rather than written directly into VS Code's private extension storage.

## Verify

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\verify-qwen3.ps1
```

This checks:

- NVIDIA GPU visibility
- Ollama model list
- Ollama HTTP tags endpoint
- A small local generation request
- Cline extension installation, when the VS Code CLI is available

## Troubleshooting

If `ollama` is not found immediately after installation, close and reopen PowerShell so the updated `PATH` is loaded.
The scripts also look for Ollama at `%LOCALAPPDATA%\Programs\Ollama\ollama.exe` so they can run in the same terminal after a fresh install.

If Cline cannot connect, verify Ollama is reachable:

```powershell
Invoke-RestMethod http://localhost:11434/api/tags
```

If the model is missing, pull it again:

```powershell
ollama pull hf.co/Qwen/Qwen3-14B-GGUF:Q4_K_M
```

If responses are slow or VRAM is tight, keep context at 32K or below and keep Cline tasks focused. Local coding agents are more sensitive to context size than cloud models.

## Sources

- Qwen official Hugging Face model card: https://huggingface.co/Qwen/Qwen3-14B-GGUF
- Qwen3-Coder official collection: https://huggingface.co/collections/Qwen/qwen3-coder
- Cline local models docs: https://docs.cline.bot/running-models-locally/overview
- Ollama Cline integration docs: https://docs.ollama.com/integrations/cline
- Cline VS Code Marketplace: https://marketplace.visualstudio.com/items?itemName=saoudrizwan.claude-dev
