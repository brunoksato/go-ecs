FROM golang:1.10.1-alpine3.7

LABEL brunoksato <bruno.sato@live.com>

RUN apk add --no-cache g++ glide

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

COPY wrapper /tmp/

RUN apk add --update-cache \
        xvfb \
        dbus \
        ttf-freefont \
        fontconfig && \
    apk add --update-cache \
            --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/ \
            --allow-untrusted \
        wkhtmltopdf && \
    apk add --update-cache \
        python \
        make \
        g++ && \
    rm -rf /var/cache/apk/* && \
    mv /usr/bin/wkhtmltopdf /usr/bin/wkhtmltopdf.ini && \
    mv /tmp/wrapper /usr/bin/wkhtmltopdf && \
    chmod +x /usr/bin/wkhtmltopdf

RUN mkdir -p /go/src/github.com/brunoksato/go-ecs

ADD . /go/src/github.com/brunoksato/go-ecs

WORKDIR /go/src/github.com/brunoksato/go-ecs
RUN glide install
    
RUN go install github.com/brunoksato/go-ecs

ENTRYPOINT ["/go/bin/go-ecs"]

EXPOSE 8080