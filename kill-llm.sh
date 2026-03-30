#!/bin/bash

# ==============================================================================
# Kill LLM Servers (MLX & Ollama)
# ==============================================================================
#
# PURPOSE:
#   Cleanly terminates any LLM servers running on the machine, specifically 
#   targeting processes on port 11434 and common background services.
#
# USAGE:
#   ./kill-llm.sh
# ==============================================================================

PORT=11434

echo "Stopping LLM services..."

# 1. Stop Ollama Desktop App (if running)
if pgrep -x "Ollama" > /dev/null; then
    echo "Quitting Ollama Desktop..."
    osascript -e 'tell application "Ollama" to quit' 2>/dev/null
fi

# 2. Kill Ollama CLI processes
if pgrep -x "ollama" > /dev/null; then
    echo "Killing ollama CLI processes..."
    pkill -x ollama
fi

# 3. Kill MLX OpenAI Server
if pgrep -f "mlx-openai-server" > /dev/null; then
    echo "Killing mlx-openai-server..."
    pkill -f mlx-openai-server
fi

# 4. Final check for anything else on port 11434
PID=$(lsof -ti :$PORT)
if [ -n "$PID" ]; then
    echo "Something is still on port $PORT (PID: $PID). Force killing..."
    kill -9 "$PID"
fi

echo "Done! Port $PORT is free."
