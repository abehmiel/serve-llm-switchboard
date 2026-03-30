# Remote LLM Serving Switchboard (MLX & Ollama)

A unified TUI for serving MLX or Ollama models on a remote macOS machine via Tailscale.

## Usage
1. Copy `serve-llm.sh` to your remote machine.
2. Ensure `gum`, `mlx-openai-server`, and `ollama` are installed.
3. Run `./serve-llm.sh`.
4. Use `./kill-llm.sh` to stop any running servers.
