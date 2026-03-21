FROM ubuntu:24.04

ARG USERNAME=agent
ARG USER_UID=1000
ARG USER_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

# --- Base tooling ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    unzip \
    iproute2 \
    iputils-ping \
    less \
    jq \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# --- Node.js 22 LTS (required for ESM compatibility in claude-code-web) ---
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# --- Google Cloud CLI ---
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update && apt-get install -y google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# --- AWS CLI v2 ---
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# --- uv (for uvx MCP servers) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# Pin npm global prefix so binaries always land in /usr/local/bin
ENV NPM_CONFIG_PREFIX=/usr/local

# --- Claude Code ---
RUN npm install -g @anthropic-ai/claude-code

# --- Claude Code Web UI ---
RUN npm install -g claude-code-web

# --- Non-root user that matches host UID/GID ---
# Ubuntu 24.04 ships a built-in 'ubuntu' user at uid/gid 1000.
# Rename it to our USERNAME and adjust its UID/GID to match the host.
RUN EXISTING_USER=$(getent passwd ${USER_UID} | cut -d: -f1) \
    && EXISTING_GROUP=$(getent group ${USER_GID} | cut -d: -f1) \
    && if [ -n "$EXISTING_USER" ] && [ "$EXISTING_USER" != "${USERNAME}" ]; then \
         usermod -l ${USERNAME} -d /home/${USERNAME} -m "$EXISTING_USER"; \
       fi \
    && if [ -n "$EXISTING_GROUP" ] && [ "$EXISTING_GROUP" != "${USERNAME}" ]; then \
         groupmod -n ${USERNAME} "$EXISTING_GROUP"; \
       fi \
    && if [ -z "$(getent passwd ${USER_UID})" ]; then \
         groupadd --gid ${USER_GID} ${USERNAME} 2>/dev/null || true; \
         useradd --uid ${USER_UID} --gid ${USER_GID} --shell /bin/bash --create-home ${USERNAME}; \
       fi


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /workspace

# Pre-create dirs so bind-mounting files doesn't create them as root
RUN mkdir -p /home/${USERNAME}/.claude /home/${USERNAME}/.aws /home/${USERNAME}/.config/gcloud \
    && chown -R ${USER_UID}:${USER_GID} /home/${USERNAME}/.claude /home/${USERNAME}/.aws /home/${USERNAME}/.config/gcloud

USER ${USERNAME}

ENTRYPOINT ["entrypoint.sh"]
CMD ["cc-web", "--port", "3000", "--no-open", "--disable-auth"]
