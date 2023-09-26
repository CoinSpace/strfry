FROM alpine:latest as build

ENV TZ=Europe/London

RUN apk add --no-cache \
    git g++ make pkgconfig libtool ca-certificates \
    perl-yaml perl-template perl-regexp-grammars libressl-dev zlib-dev \
    lmdb-dev flatbuffers-dev secp256k1-dev zstd-dev

WORKDIR /build
COPY . .

RUN git submodule update --init
RUN make setup-golpe
RUN make -j4

FROM alpine:latest as runner

RUN apk add --no-cache \
    liblmdb libflatbuffers libsecp256k1 libb2 libzstd

RUN rm -rf /var/cache/apk/*

COPY --from=build /build/strfry ./strfry
COPY ./strfry-db ./strfry-db
COPY ./strfry.conf /etc/strfry.conf

RUN apk add --no-cache nginx curl gnupg tini lsb-release

RUN gcsFuseRepo=gcsfuse-$(lsb_release -c -s) && \
    echo "http://packages.cloud.google.com/apt $gcsFuseRepo main" >> /etc/apk/repositories && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apk add --no-cache gnupg && \
    apk add --no-cache gcsfuse && apk del --purge gnupg

ENV MNT_DIR /strfry-db

COPY ./STAR.purplerelay.com.key /etc/ssl/STAR.purplerelay.com.key
COPY ./ssl-bundle.crt /etc/ssl/ssl-bundle.crt

COPY --from=build /build/nginx/nginx.conf /etc/nginx/nginx.conf
COPY --from=build /build/nginx/new.default.conf /etc/nginx/conf.d/default.conf

COPY ./run.sh ./run.sh
RUN chmod +x ./run.sh

COPY ./setup_gcloud_cli.sh ./setup_gcloud_cli.sh
RUN chmod +x ./setup_gcloud_cli.sh
RUN ./setup_gcloud_cli.sh

COPY ./application_default_credentials.json /root/.config/gcloud/application_default_credentials.json

# Expose ports
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./run.sh"]