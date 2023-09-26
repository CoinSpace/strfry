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
    apt-transport-https \
    ca-certificates \
    gnupg \
    curl \
    perl-yaml \
    perl-template-toolkit \
    perl-app-cpanminus \
    libressl-dev \
    zlib-dev \
    lmdb-dev \
    flatbuffers-dev \
    libsecp256k1-dev \
    zstd-dev \
  && rm -rf /var/cache/apk/* \
  && cpanm Regexp::Grammars \
  && git submodule update --init \
  && make setup-golpe \
  && make -j4

FROM alpine:3.18.3

WORKDIR /app
COPY --from=build /build/strfry ./strfry
COPY ./strfry-db ./strfry-db
COPY ./strfry.conf ./etc/strfry.conf

RUN \
  apk --no-cache add \
    lmdb \
    flatbuffers \
    libsecp256k1 \
    libb2 \
    zstd \
    libressl \
    nginx \
  && rm -rf /var/cache/apk/*
ENV MNT_DIR ./strfry-db

COPY ./STAR.purplerelay.com.key /etc/ssl/STAR.purplerelay.com.key
COPY ./ssl-bundle.crt /etc/ssl/ssl-bundle.crt

COPY --from=build ./build/nginx/nginx.conf ./
COPY --from=build ./build/nginx/new.default.conf ./

COPY --from=build ./run.sh ./run.sh
RUN chmod +x ./run.sh

COPY --from=build ./setup_gcloud_cli.sh ./setup_gcloud_cli.sh
RUN chmod +x ./setup_gcloud_cli.sh
RUN ./setup_gcloud_cli.sh
COPY ./application_default_credentials.json ./$HOME/.config/gcloud/application_default_credentials.json

COPY --from=build /build/strfry strfry

EXPOSE 80
EXPOSE 443
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["./run.sh"]
