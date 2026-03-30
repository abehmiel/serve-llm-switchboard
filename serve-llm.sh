#!/bin/bash

# ==============================================================================
# Remote LLM Serving Switchboard (MLX & Ollama)
# ==============================================================================
#
# PURPOSE:
#   This script allows you to easily choose between serving models via MLX 
#   (mlx-openai-server) or Ollama on port 11434. It is optimized for 
#   Apple Silicon and designed to be accessible via Tailscale.
#
# USAGE:
#   Run this script on your REMOTE machine (the one with the GPU/NPU).
#   ./serve-llm.sh
#
# DEPENDENCIES:
#   - gum (brew install gum)
#   - mlx-openai-server (pip install mlx-openai-server)
#   - ollama (https://ollama.com)
#   - lsof (standard on macOS)
#
# REMOTE ACCESS:
#   Once running, you can connect from another machine on your Tailnet at:
#   http://<remote-mac-hostname>:11434
# ==============================================================================

# Required tools
DEPENDENCIES=("gum" "ollama" "mlx-openai-server" "lsof")

check_deps() {
    for dep in "${DEPENDENCIES[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Error: $dep is not installed. Please install it first."
            exit 1
        fi
    done
}

# Main initialization
check_deps
echo "All dependencies found."

PORT=11434

cleanup_port() {
    local pid=$(lsof -ti :$PORT)
    if [ -n "$pid" ]; then
        local proc_name=$(ps -p "$pid" -o comm=)
        echo "Port $PORT is occupied by $proc_name (PID: $pid)"
        if gum confirm "Kill $proc_name to free up port $PORT?"; then
            kill -9 "$pid"
            echo "Killed $pid. Port $PORT is now free."
        else
            echo "Port $PORT is still occupied. Exiting."
            exit 1
        fi
    fi
}

serve_mlx() {
    echo "Scanning for MLX models..."
    # Parse repo IDs from mlx_lm.manage --scan
    # Skip header lines (usually 3 or 4)
    local models=$(mlx_lm.manage --scan 2>/dev/null | tail -n +4 | awk '{print $1}')
    
    if [ -z "$models" ]; then
        echo "No MLX models found."
        local hf_id=$(gum input --placeholder "Enter Hugging Face model ID to download (e.g. mlx-community/Llama-3.2-3B-Instruct-4bit)")
        [ -z "$hf_id" ] && exit 0
        mlx-openai-server --model "$hf_id" --port $PORT --host 0.0.0.0
    else
        local choice=$(echo -e "$models
Download New..." | gum filter --placeholder "Select MLX model")
        
        if [ "$choice" == "Download New..." ]; then
            local hf_id=$(gum input --placeholder "Enter Hugging Face model ID")
            [ -z "$hf_id" ] && exit 0
            mlx-openai-server --model "$hf_id" --port $PORT --host 0.0.0.0
        elif [ -n "$choice" ]; then
            mlx-openai-server --model "$choice" --port $PORT --host 0.0.0.0
        fi
    fi
}

serve_ollama() {
    echo "Scanning for Ollama models..."
    local models=$(ollama list 2>/dev/null | tail -n +2 | awk '{print $1}')
    
    local choice=$(echo -e "$models
Download New..." | gum filter --placeholder "Select Ollama model")
    
    if [ "$choice" == "Download New..." ]; then
        local model_name=$(gum input --placeholder "Enter Ollama model name (e.g. llama3.2)")
        [ -z "$model_name" ] && exit 0
        OLLAMA_HOST=0.0.0.0:$PORT ollama run "$model_name"
    elif [ -n "$choice" ]; then
        echo "Starting Ollama server for $choice..."
        OLLAMA_HOST=0.0.0.0:$PORT ollama run "$choice"
    fi
}

main() {
    # check_deps # already called at top level
    cleanup_port
    
    local engine=$(gum choose "MLX" "Ollama" "Exit")
    
    case $engine in
        "MLX")
            serve_mlx
            ;;
        "Ollama")
            serve_ollama
            ;;
        "Exit")
            exit 0
            ;;
    esac
}

main
