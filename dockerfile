FROM python:3.10-slim

# Create non-root user 'forge' with UID 99 and GID 100 (Unraid compatibility)
RUN useradd -u 99 -g 100 -d /home/forge forge

WORKDIR /home/forge

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    bc \
    libgtk2.0-dev \
    libgoogle-perftools-dev \
    && rm -rf /var/lib/apt/lists/*

# Clone the repository
RUN git clone https://github.com/lllyasviel/stable-diffusion-webui-forge.git 
 
# Fix ownership
RUN chown -R forge:users /home && \
    chmod +x ./stable-diffusion-webui-forge/webui.sh

WORKDIR ./stable-diffusion-webui-forge

# Switch to non-root user
USER forge

# Create virtual environment and upgrade pip
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --no-cache-dir --upgrade pip && \
    deactivate

# Install main requirements    
RUN  . venv/bin/activate && \
    pip install --no-cache-dir numpy==1.26.2 && \
    pip install --no-cache-dir -r requirements_versions.txt && \
    deactivate    

# Install specific versions of PyTorch and xformers first
RUN . venv/bin/activate && \
    pip install --no-cache-dir torch==2.3.1 torchvision==0.18.1 torchaudio==2.3.1 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install --no-cache-dir xformers==0.0.27 && \
    deactivate

# Install built-in extension requirements    
RUN  . venv/bin/activate && \
    pip install --no-cache-dir -r extensions-builtin/sd_forge_controlnet/requirements.txt && \
    pip install --no-cache-dir -r extensions-builtin/forge_legacy_preprocessors/requirements.txt && \
    deactivate
 
# Install built-in problematic requirements    
RUN  . venv/bin/activate && \
    pip install --no-cache-dir insightface && \
    pip uninstall -y onnxruntime && \
    pip install --no-cache-dir onnxruntime-gpu && \
    pip install --no-cache-dir protobuf==3.2.0 && \
    deactivate

# Expose the default web UI port
EXPOSE 7860

# Entry point (runs webui.sh)
ENTRYPOINT ["/bin/bash", "-c", "./webui.sh"]
