# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bazzite-deck:stable

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

RUN curl -L -o /tmp/powerstation.rpm \
	https://github.com/ShadowBlip/PowerStation/releases/download/v0.8.1/powerstation-0.8.1-1.x86_64.rpm && \
	dnf5 install -y /tmp/powerstation.rpm && rm -rf /tmp/powerstation.rmp

RUN curl -L -o /tmp/ogui.tar.gz \
      https://github.com/Svitkona/OpenGamepadUI/releases/download/ogui-fix/opengamepadui.tar.gz && \
    tar xzf /tmp/ogui.tar.gz -C /tmp && \
    cd /tmp/opengamepadui && make install PREFIX=/usr && \
    rm -rf /tmp/ogui.tar.gz /tmp/opengamepadui

COPY gamescope-session-config/opengamepadui /usr/share/gamescope-session-plus/sessions.d/opengamepadui
COPY gamescope-session-config/gamescope-session-opengamepadui.desktop /usr/share/wayland-sessions/gamescope-session-opengamepadui.desktop
COPY gamescope-session-config/steamos.conf /usr/share/bazzite-inputplumber/steamos.conf
COPY gamescope-session-config/sddm-session.conf /usr/lib/tmpfiles.d/sddm-session.conf

### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
