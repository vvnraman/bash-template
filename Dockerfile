FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
    bats \
    bash \
    coreutils \
    diffutils \
    findutils \
    gawk \
    grep \
    sed \
    util-linux

WORKDIR /work

CMD ["bats", "tests"]
