# Built by Akito
# npub1wprtv89px7z2ut04vvquscpmyfuzvcxttwy2csvla5lvwyj807qqz5aqle

FROM alpine:3.18.3 AS build

ENV TZ=Europe/London

WORKDIR /build

COPY . .

RUN ls -lhtra

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

RUN \
  wget https://go.dev/dl/go1.21.1.linux-amd64.tar.gz -O /tmp/go.tar.gz && \
  tar -C /usr/local -xzf /tmp/go.tar.gz && \
  rm /tmp/go.tar.gz

ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go

RUN \
  wget https://dl.google.com/dl/cloudsdk/release/google-cloud-sdk.tar.gz && \
  tar xzf google-cloud-sdk.tar.gz && \
  ./google-cloud-sdk/install.sh --usage-reporting false --path-update false --quiet && \
  rm ./google-cloud-sdk.tar.gz

ENV PATH=/google-cloud-sdk/bin:${PATH}

COPY --from=build /build/strfry strfry

COPY ./STAR.purplerelay.com.key /etc/ssl/STAR.purplerelay.com.key
COPY ./ssl-bundle.crt /etc/ssl/ssl-bundle.crt

COPY --from=build ./build/nginx/nginx.conf ./
COPY --from=build ./build/nginx/new.default.conf ./

# COPY --from=build ./setup_gcloud_cli.sh ./setup_gcloud_cli.sh
# RUN chmod +x ./setup_gcloud_cli.sh
# RUN ./setup_gcloud_cli.sh

COPY --from=build ./application_default_credentials.json ./$HOME/.config/gcloud/application_default_credentials.json

COPY ./strfry.conf /etc/strfry.conf
COPY ./strfry-db ./strfry-db

COPY ./run.sh ./run.sh
RUN chmod +x ./run.sh

EXPOSE 80
EXPOSE 443

CMD ["./run.sh"]