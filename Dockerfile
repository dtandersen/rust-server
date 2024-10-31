# FROM didstopia/base:nodejs-12-steamcmd-ubuntu-18.04
FROM steamcmd/steamcmd:latest

LABEL maintainer="https://github.com/dtandersen/rust-server"

# Fix apt-get warnings
# ARG DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
# apt-get install -y --no-install-recommends \
    nginx \
    # expect \
    # tcl \
    tini \
    unzip \
    libarchive-tools \
    curl && \
	# libsdl2-2.0-0:i386 \
    # libgdiplus && \
    rm -rf /var/lib/apt/lists/*

# Remove default nginx stuff
RUN rm -fr /usr/share/nginx/html/* && \
	rm -fr /etc/nginx/sites-available/* && \
	rm -fr /etc/nginx/sites-enabled/*

# COPY rcon.yaml /etc
COPY rcon /usr/local/bin
COPY healthz /usr/local/bin
RUN mkdir -p /opt/rcon && \
    curl -sL https://github.com/gorcon/rcon-cli/releases/download/v0.10.3/rcon-0.10.3-i386_linux.tar.gz | tar -zxvf- --strip-components=1 -C /opt/rcon

# ENV PATH=$PATH:/opt/rcon
#  && \
    # 	mv /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b/* /usr/share/nginx/html/ && \
    # 	rm -fr /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b
    

# Install webrcon (specific commit)
# COPY nginx_rcon.conf /etc/nginx/nginx.conf
# RUN curl -sL https://github.com/Facepunch/webrcon/archive/24b0898d86706723d52bb4db8559d90f7c9e069b.zip | bsdtar -xvf- -C /tmp && \
# 	mv /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b/* /usr/share/nginx/html/ && \
# 	rm -fr /tmp/webrcon-24b0898d86706723d52bb4db8559d90f7c9e069b

# Customize the webrcon package to fit our needs
# ADD fix_conn.sh /tmp/fix_conn.sh

# Create the volume directories
RUN mkdir -p /steamcmd/rust /usr/share/nginx/html /var/log/nginx

# # Setup proper shutdown support
# ADD shutdown_app/ /app/shutdown_app/
# WORKDIR /app/shutdown_app
# RUN npm install

# # Setup restart support (for update automation)
# ADD restart_app/ /app/restart_app/
# WORKDIR /app/restart_app
# # disabled - doesn't install
# #RUN npm install

# # Setup scheduling support
# ADD scheduler_app/ /app/scheduler_app/
# WORKDIR /app/scheduler_app
# RUN npm install

# # Setup scheduling support
# ADD heartbeat_app/ /app/heartbeat_app/
# WORKDIR /app/heartbeat_app
# RUN npm install

# Setup rcon command relay app
# ADD rcon_app/ /app/rcon_app/
# WORKDIR /app/rcon_app
# RUN npm install
# RUN ln -s /app/rcon_app/app.js /usr/bin/rcon

# Add the steamcmd installation script
# ADD install.txt /app/install.txt

# Copy the Rust startup script
COPY entrypoint.sh /

# Copy the Rust update check script
# ADD update_check.sh /app/update_check.sh

# Copy extra files
# COPY README.md LICENSE.md /app/

# Set the current working directory
WORKDIR /

# Fix permissions
RUN chown -R 1000:1000 \
    /steamcmd \
    # /app \
    /usr/share/nginx/html \
    /var/log/nginx

WORKDIR /steamcmd/rust

# Run as a non-root user by default
ENV PGID=1000 \
    PUID=1000

# server port
EXPOSE 28015/udp 
# rcon port
EXPOSE 28016/tcp
# query port
EXPOSE 28017/udp
# rust+
EXPOSE 28082/tcp
# rcon web interface
EXPOSE 8080/tcp  

# Setup default environment variables for the server
ENV RUST_SERVER_STARTUP_ARGUMENTS="-batchmode -load -nographics +server.secure 1" \
    RUST_SERVER_IDENTITY="docker" \
    RUST_SERVER_PORT="" \
    RUST_SERVER_QUERYPORT="" \
    RUST_SERVER_CUSTOMMAP_ENABLED="0" \
    RUST_SERVER_LEVEL_URL="" \
    RUST_SERVER_SEED="12345" \
    RUST_SERVER_NAME="Rust Server [DOCKER]" \
    RUST_SERVER_DESCRIPTION="This is a Rust server running inside a Docker container!" \
    RUST_SERVER_URL="https://hub.docker.com/r/didstopia/rust-server/" \
    RUST_SERVER_BANNER_URL="" \
    RUST_RCON_WEB="1" \
    RUST_RCON_PORT="28016" \
    RUST_RCON_PASSWORD="docker" \
    RUST_APP_PORT="28082" \
    RUST_UPDATE_CHECKING="0" \
    RUST_HEARTBEAT="0" \
    RUST_UPDATE_BRANCH="public" \
    RUST_START_MODE="0" \
    RUST_OXIDE_ENABLED="0" \
    RUST_OXIDE_UPDATE_ON_BOOT="1" \
    RUST_CARBON_ENABLED="0" \
    RUST_CARBON_UPDATE_ON_BOOT="1" \
    RUST_CARBON_BRANCH="" \
    RUST_RCON_SECURE_WEBSOCKET="0" \
    RUST_SERVER_WORLDSIZE="3500" \
    RUST_SERVER_MAXPLAYERS="500" \
    RUST_SERVER_SAVE_INTERVAL="600" \
    CHOWN_DIRS="/app,/steamcmd,/usr/share/nginx/html,/var/log/nginx"

# Expose the volumes
# VOLUME [ "/steamcmd/rust" ]

# Start the server
ENTRYPOINT [ "tini", "--" ]
CMD ["/entrypoint.sh"]
