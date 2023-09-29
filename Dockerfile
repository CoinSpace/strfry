# Built by Akito
# npub1wprtv89px7z2ut04vvquscpmyfuzvcxttwy2csvla5lvwyj807qqz5aqle

FROM alpine:3.18.3 AS build

ENV TZ=Europe/London

WORKDIR /build

COPY . .

RUN \
  apk --no-cache add \
    linux-headers \
    git \
    g++ \
    make \
    pkgconfig \
    libtool \
    ca-certificates \
    perl-yaml \
    perl-template-toolkit \
    perl-app-cpanminus \
    libressl-dev \
    zlib-dev \
    lmdb-dev \
    flatbuffers-dev \
    libsecp256k1-dev \
    zstd-dev \
    nginx \
  && rm -rf /var/cache/apk/* \
  && cpanm Regexp::Grammars \
  && git submodule update --init \
  && make setup-golpe \
  && make -j4

FROM alpine:3.18.3
ENV MNT_DIR ./strfry-db

WORKDIR /app

RUN \
  apk --no-cache add \
    lmdb \
    flatbuffers \
    libsecp256k1 \
    libb2 \
    zstd \
    libressl \
  && rm -rf /var/cache/apk/*

RUN \
  apk --no-cache add \
    nginx \
    lsb-release \
    fuse \
    fuse-dev \
    git \
    python3 \
    py3-crcmod \
    libc6-compat \
    openssh-client \
  && rm -rf /var/cache/apk/*

COPY ./setup_gcloud_cli.sh ./setup_gcloud_cli.sh
COPY ./setup_gcsfuse.sh ./setup_gcsfuse.sh

RUN chmod +x ./setup_gcloud_cli.sh ./setup_gcsfuse.sh
RUN ./setup_gcloud_cli.sh
RUN ./setup_gcsfuse.sh

RUN rm ./setup_gcloud_cli.sh ./setup_gcsfuse.sh

COPY --from=build /build/strfry strfry

COPY ./STAR.purplerelay.com.key /etc/ssl/STAR.purplerelay.com.key
COPY ./ssl-bundle.crt /etc/ssl/ssl-bundle.crt

COPY --from=build ./build/nginx/nginx.conf ./
COPY --from=build ./build/nginx/new.default.conf ./
RUN mkdir -p /var/www/media
COPY --from=build ./build/nginx/favicon.ico /var/www/media/favicon.ico

COPY --from=build ./build/application_default_credentials.json $HOME/.config/gcloud/application_default_credentials.json

COPY ./strfry.conf /etc/strfry.conf
COPY ./strfry-db ./strfry-db

COPY ./import_db.sh ./import_db.sh
RUN chmod +x ./import_db.sh
RUN ./import_db.sh

COPY ./run.sh ./run.sh
RUN chmod +x ./run.sh

EXPOSE 80
EXPOSE 443

CMD ["./run.sh"]