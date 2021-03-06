FROM nfxus/mono:latest

ARG MEDIAINFO_VER=0.7.98
ARG EMBY_VER=3.2.36.0

ENV GID=991 \
    UID=991 \
    PREMIERE=false

LABEL description="Emby based on alpine based on mono 4.8" \
      tags="latest 3.2.36.0 3.2 3" \
      maintainer="RaymondSchnyder <https://github.com/raymondschnyder>" \
      build_ver="20171115"

RUN export BUILD_DEPS="build-base \
                        git \
                        unzip \
                        wget \
			curl \
                        ca-certificates \
                        xz" \
    && apk add --no-cache imagemagick \
	            sqlite-libs \
	            s6 \
                su-exec \
                $BUILD_DEPS \
    && wget http://mediaarea.net/download/binary/mediainfo/${MEDIAINFO_VER}/MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.xz -O /tmp/MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.xz \
    && wget http://mediaarea.net/download/binary/libmediainfo0/${MEDIAINFO_VER}/MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.xz -O /tmp/MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.xz \
    && wget https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-64bit-static.tar.xz -O /tmp/ffmpeg-static.tar.xz \
    && tar xJf /tmp/MediaInfo_DLL_${MEDIAINFO_VER}_GNU_FromSource.tar.xz -C /tmp \
    && tar xJf /tmp/MediaInfo_CLI_${MEDIAINFO_VER}_GNU_FromSource.tar.xz -C /tmp \
    && tar xJf /tmp/ffmpeg-static.tar.xz -C /tmp \
    && cd /tmp/ffmpeg-*/ \
    && mv ffmpeg /usr/bin/ffmpeg \
    && mv ffprobe /usr/bin/ffprobe \
    && cd  /tmp/MediaInfo_DLL_GNU_FromSource \
    && ./SO_Compile.sh \
    && cd /tmp/MediaInfo_DLL_GNU_FromSource/ZenLib/Project/GNU/Library \
    && make install \
    && cd /tmp/MediaInfo_DLL_GNU_FromSource/MediaInfoLib/Project/GNU/Library \
    && make install \
    && cd /tmp/MediaInfo_CLI_GNU_FromSource \
    && ./CLI_Compile.sh \
    && cd /tmp/MediaInfo_CLI_GNU_FromSource/MediaInfo/Project/GNU/CLI \
    && make install \
    && mkdir /embyServer /embyData \
    && wget https://github.com/MediaBrowser/Emby/releases/download/${EMBY_VER}/Emby.Mono.zip -O /tmp/Emby.Mono.zip \
    && ln -s /usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so \
    && unzip /tmp/Emby.Mono.zip -d /embyServer \
    && apk del --no-cache $BUILD_DEPS \
    && rm -rf /tmp/*

EXPOSE 8096 8920 7359/udp
VOLUME /embyData
ADD rootfs /
RUN chmod +x /usr/local/bin/startup

ENTRYPOINT ["/usr/local/bin/startup"]
CMD ["s6-svscan", "/etc/s6.d"]

HEALTHCHECK --interval=200s --timeout=100s CMD curl --fail http://localhost:8096/web || exit 1
