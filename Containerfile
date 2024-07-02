FROM registry.access.redhat.com/ubi9/ubi:latest@sha256:081c96d1b1c7cd1855722d01f1ca53360510443737b1eb33284c6c4c330e537c as builder
RUN dnf -y install \
    make \
    golang \
    glib2-devel \
    gpgme-devel \
    libassuan-devel \
    libseccomp-devel \
    git \
    bzip2 \
    runc \
    containers-common

WORKDIR /go/src/containers/buildah

COPY buildah/ .

RUN make buildah

# Rebase on ubi9
FROM registry.access.redhat.com/ubi9:latest@sha256:d98fdae16212df566150ac975cab860cd8d2cb1b322ed9966d09a13e219112e9

COPY --from=builder /go/src/containers/buildah/bin/buildah /usr/bin/buildah

WORKDIR /workdir

RUN \
  groupadd -g 1000 buildah; \
  useradd -u 1000 -g buildah -s /bin/sh -d /home/buildah buildah

RUN chown -R buildah:buildah /workdir

USER buildah

ENTRYPOINT ["/usr/bin/buildah"]
