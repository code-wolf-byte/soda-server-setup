#!/bin/bash

# Define the folder path
FOLDER_PATH="/soda-internal-api"
SESSION_NAME="soda-internal-api"
ENV_NAME="soda_env"
CADDYFILE_PATH="/etc/caddy/Caddyfile"
# Check if the folder exists
if [ -d "$FOLDER_PATH" ]; then
    #pass 
else
  echo "API not found: $FOLDER_PATH. Run setup.sh first."
  exit 1
fi


# Check if the tmux session exists
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "Attaching to existing tmux session '$SESSION_NAME'."
  tmux attach-session -t "$SESSION_NAME"
else
  echo "Creating new tmux session '$SESSION_NAME'."
  tmux new-session -s "$SESSION_NAME"
fi

cd "$FOLDER_PATH"

conda activate "$ENV_NAME"

echo "Starting Flask app using Gunicorn and tmux..."
tmux new-session -d -s flask_app "gunicorn -w 4 -b 0.0.0.0:8000 main:app"


tmux detach

echo "Configuring Caddy..."
CADDYFILE_PATH="/etc/caddy/Caddyfile"
echo "Killing any running Caddy process..."
pkill caddy

# Wait for a moment to ensure Caddy is completely terminated
sleep 2

# Create the Caddy configuration file
echo "Creating Caddy configuration file..."
cat <<EOL > $CADDYFILE_PATH
:8000 {
    reverse_proxy api.thesoda.io
}
EOL

# Start Caddy with the configuration
echo "Starting Caddy with the new configuration..."
caddy run --config $CADDYFILE_PATH

echo "Caddy reverse proxy started on :8000, forwarding to api.thesoda.io"