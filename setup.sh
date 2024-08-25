#!/bin/bash

API_REPO="https://github.com/asusoda/soda-internal-api.git"
MAIN_WEBSITE_REPO="https://github.com/asusoda/asu-soda-newsite.git"
ADMIN_WEBSITE_REPO="https://github.com/asusoda/soda-admin.git"

ENV_NAME="soda_env"
CHROMEDRIVER_VERSION="114.0.5735.90"  # Replace this with the appropriate version of ChromeDriver

# Install Miniconda (if not already installed)
if ! command -v conda &> /dev/null; then
    echo "Conda not found, installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p $HOME/miniconda
    export PATH="$HOME/miniconda/bin:$PATH"
    conda init bash
    source ~/.bashrc
    rm miniconda.sh
else
    echo "Conda is already installed."
fi

# Create or activate the Conda environment
if conda info --envs | grep "$ENV_NAME"; then
    echo "Environment '$ENV_NAME' already exists, activating it..."
    conda activate "$ENV_NAME"
else
    echo "Creating a new Conda environment '$ENV_NAME'..."
    conda create -y -n "$ENV_NAME" python=3.9
    conda activate "$ENV_NAME"
fi

# Clone the API repository
git clone $API_REPO soda-internal-api
cd soda-internal-api
echo "API repo cloned successfully"

# Install dependencies from requirements.txt if it exists
if [ -f "requirements.txt" ]; then
  echo "Installing dependencies from requirements.txt..."
  pip install -r requirements.txt
else
  echo "No requirements.txt found, skipping dependency installation."
fi

# Install ChromeDriver
echo "Installing ChromeDriver..."
CHROMEDRIVER_URL="https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip"
curl -O "$CHROMEDRIVER_URL"
unzip chromedriver_linux64.zip -d "$CONDA_PREFIX/bin"
chmod +x "$CONDA_PREFIX/bin/chromedriver"
rm chromedriver_linux64.zip

echo "ChromeDriver installed successfully in '$CONDA_PREFIX/bin/chromedriver'."

# Install Caddy
echo "Installing Caddy..."
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install caddy -y

# Setup Gunicorn to run the Flask app
echo "Installing Gunicorn..."
pip install gunicorn

# Start the Flask app with Gunicorn inside a tmux session

# Configure Caddy to proxy requests to the Flask app
echo "Configuring Caddy..."
CADDYFILE_PATH="/etc/caddy/Caddyfile"
sudo bash -c "cat > $CADDYFILE_PATH" <<EOL
{
    email your-email@example.com
}

your-domain.com {
    reverse_proxy 127.0.0.1:8000
    sudo apt install tmux

}
EOL

# Restart Caddy to apply the configuration
sudo systemctl restart caddy

echo "Caddy is configured and serving your Flask app."

# Deactivate the Conda environment
conda deactivate
