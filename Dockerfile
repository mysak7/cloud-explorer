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
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# --- AWS CLI v2 ---
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws

# --- uv (for uvx MCP servers) ---
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# --- Claude Code ---
RUN npm install -g @anthropic-ai/claude-code

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

# Re-expose uv for the agent user
RUN cp -r /root/.local/bin/uv* /usr/local/bin/ 2>/dev/null || true

WORKDIR /workspace

# Pre-create .claude dir so bind-mounting credentials.json doesn't create it as root
RUN mkdir -p /home/${USERNAME}/.claude && chown ${USER_UID}:${USER_GID} /home/${USERNAME}/.claude

USER ${USERNAME}

CMD ["bash"]
