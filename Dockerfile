FROM nfnty/arch-mini

RUN pacman --sync --noconfirm --refresh --sysupgrade && \
    pacman --sync --noconfirm \
      busybox clang cmake curl diffutils git grep llvm llvm-libs make ncurses python2 sed subversion vim wget which && \
    find /var/cache/pacman/pkg -mindepth 1 -delete

WORKDIR /build-stage

ADD tools /build-stage/tools
RUN tools/scripts/build.sh

CMD ["/build-stage/tools/scripts/package.sh"]
