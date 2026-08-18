ARG DEBIAN_DIST=bookworm
FROM debian:$DEBIAN_DIST

ARG DEBIAN_DIST
ARG rclone_VERSION
ARG BUILD_VERSION
ARG FULL_VERSION
ARG ARCH
ARG RCLONE_RELEASE

RUN mkdir -p /output/usr/bin
RUN mkdir -p /output/usr/sbin
RUN mkdir -p /output/usr/share/doc/rclone
RUN mkdir -p /output/usr/share/man/man1
RUN mkdir -p /output/usr/share/bash-completion/completions
RUN mkdir -p /output/usr/share/fish/vendor_completions.d
RUN mkdir -p /output/usr/share/zsh/vendor-completions
RUN mkdir -p /output/DEBIAN

COPY ${RCLONE_RELEASE}/rclone /output/usr/bin/
COPY ${RCLONE_RELEASE}/rclone.1 /output/usr/share/man/man1/
# rclone does not ship completions in the release zip; build_debian.sh generates
# them with `rclone completion <shell>` before the image is built.
COPY completions/rclone.bash /output/usr/share/bash-completion/completions/rclone
COPY completions/rclone.fish /output/usr/share/fish/vendor_completions.d/rclone.fish
COPY completions/_rclone /output/usr/share/zsh/vendor-completions/_rclone
RUN chmod 755 /output/usr/bin/rclone
RUN chmod 644 /output/usr/share/man/man1/rclone.1
RUN gzip -9n /output/usr/share/man/man1/*.1
# Match Debian's rclone package, which ships mount.rclone so that
# `mount -t rclone` and fstab entries work.
RUN ln -s ../bin/rclone /output/usr/sbin/mount.rclone
RUN ln -s rclone.1.gz /output/usr/share/man/man1/mount.rclone.1.gz
COPY output/DEBIAN/control /output/DEBIAN/
COPY output/DEBIAN/postinst /output/DEBIAN/postinst
RUN chmod 755 /output/DEBIAN/postinst
COPY output/copyright /output/usr/share/doc/rclone/
COPY output/changelog.Debian /output/usr/share/doc/rclone/
COPY output/README.md /output/usr/share/doc/rclone/

RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/usr/share/doc/rclone/changelog.Debian
RUN sed -i "s/FULL_VERSION/$FULL_VERSION/" /output/usr/share/doc/rclone/changelog.Debian
RUN sed -i "s/DIST/$DEBIAN_DIST/" /output/DEBIAN/control
RUN sed -i "s/rclone_VERSION/$rclone_VERSION/" /output/DEBIAN/control
RUN sed -i "s/BUILD_VERSION/$BUILD_VERSION/" /output/DEBIAN/control
RUN sed -i "s/SUPPORTED_ARCHITECTURES/$ARCH/" /output/DEBIAN/control

# Normalise permissions (files arrive from the host with the builder's umask)
RUN find /output/usr -type f -exec chmod 644 {} + && chmod 755 /output/usr/bin/rclone

RUN dpkg-deb --build /output /rclone_${FULL_VERSION}.deb
