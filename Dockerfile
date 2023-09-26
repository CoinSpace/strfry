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
  && rm -rf /var/cache/apk/* \
  && cpanm Regexp::Grammars \
  && git submodule update --init \
  && make setup-golpe \
  && make -j4

FROM alpine:3.18.3

WORKDIR /app

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

RUN adduser -D -g 'www' www
RUN mkdir /www
RUN chown -R www:www /var/lib/nginx && chown -R www:www /www

COPY --from=build /build/strfry strfry

RUN ls -lhtra strfry

COPY --from=build ./build/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build ./build/nginx/new.default.conf /etc/nginx/sites-enabled/default.conf

RUN rc-service nginx start

EXPOSE 7777
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/app/strfry"]
CMD ["relay"]