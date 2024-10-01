# Use Python 3.12 as the base image
FROM python:3.12

# Set working directory to /app
WORKDIR /app

# Expose the desired port
EXPOSE 8191

# Set environment variables to configure Python and Poetry
ENV \
    DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    INSTALL_NOVNC=false \
    DISPLAY=:1.0 \
    CHROME_FLAGS="--no-sandbox --disable-dev-shm-usage --disable-gpu --headless"

# Create a non-root user to avoid root Chrome issues
RUN useradd -ms /bin/bash nonrootuser

# Update apt, install necessary packages, and install sudo
RUN apt update && apt upgrade -y && \
    apt install -y wget gnupg unzip curl xvfb x11vnc fluxbox sudo --no-install-recommends && \
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt install -y ./google-chrome-stable_current_amd64.deb && \
    rm ./google-chrome-stable_current_amd64.deb

# Add nonrootuser to the sudoers file with no password prompt
RUN echo "nonrootuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install pipx and Poetry for dependency management
RUN apt install -y pipx && \
    pipx ensurepath && \
    pipx install poetry

# Ensure Poetry is on the PATH
ENV PATH="/root/.local/bin:$PATH"

# Copy the Python project files (pyproject.toml and poetry.lock)
COPY pyproject.toml poetry.lock ./

# Install the dependencies using Poetry
RUN poetry install

# Copy the novnc.sh script and run it if needed
COPY novnc.sh .
RUN ./novnc.sh

# Copy the fix_nodriver.py script
COPY fix_nodriver.py ./

# Activate virtual environment and run the fix_nodriver script
RUN . /app/.venv/bin/activate && python fix_nodriver.py

# Copy the remaining project files
COPY . .

# Ensure Chrome runs with the correct flags for a headless, root environment
ENV CHROME_BINARY="/usr/bin/google-chrome-stable"

# Add a shell script to launch Chrome with no-sandbox
RUN echo '#!/bin/bash\n$CHROME_BINARY $CHROME_FLAGS "$@"' > /usr/bin/chrome-wrapper && chmod +x /usr/bin/chrome-wrapper

# Switch to non-root user
USER nonrootuser

# Set the command for running your Python app
CMD /usr/local/share/desktop-init.sh && . /app/.venv/bin/activate && python main.py
