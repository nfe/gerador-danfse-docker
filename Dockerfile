# syntax=docker/dockerfile:1
# Imagem do DANFSe Service da Receita Federal (MIT), construída a partir do
# código oficial fixado em um commit. Este repositório não copia o código.
ARG UPSTREAM_REPO=https://github.com/ReceitaFederal/calculadora-rtc-gerador-danfse.git
ARG UPSTREAM_REF=8d79e6b2f7fad6375340afcb51c85ed370c64a14

FROM --platform=$BUILDPLATFORM golang:1.27.3 AS build
ARG UPSTREAM_REPO
ARG UPSTREAM_REF
ARG TARGETOS=linux
ARG TARGETARCH=amd64
WORKDIR /src
RUN git init -q . \
 && git fetch -q --depth 1 "$UPSTREAM_REPO" "$UPSTREAM_REF" \
 && git checkout -q FETCH_HEAD
# Correções de segurança ainda não aplicadas no upstream (Trivy, 25/11/2026). Remover quando o upstream atualizar.
# BuildKit injeta OTEL_EXPORTER_OTLP_TRACES_* nos RUN; os testes de telemetria precisam do ambiente limpo.
RUN go get github.com/labstack/echo/v5@v5.4.1 golang.org/x/net@v0.62.0 golang.org/x/image@v0.45.0 \
      google.golang.org/grpc@v1.83.2 \
 && go mod tidy \
 && env $(env | grep -o "^OTEL_[A-Z_]*" | sed "s/^/-u /") go test -count=1 ./...
# shortcut: usa o api/swagger já versionado no upstream (não roda swag init); regerar se o upstream deixar de versioná-lo.
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/danfse-service ./cmd/danfse \
 && cp LICENSE /out/LICENSE.upstream

FROM alpine:3.22
ARG UPSTREAM_REF
LABEL org.opencontainers.image.title="danfse-service" \
      org.opencontainers.image.description="DANFSe Service (Receita Federal) empacotado pela NFE.io" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/nfe/gerador-danfse-docker" \
      io.nfe.upstream.repo="https://github.com/ReceitaFederal/calculadora-rtc-gerador-danfse" \
      io.nfe.upstream.ref="${UPSTREAM_REF}"
RUN apk add --no-cache ca-certificates tzdata
COPY --from=build /out/ /app/
ENV TZ=America/Sao_Paulo \
    SERVER_PORT=8080
USER 65532:65532
EXPOSE 8080
# Cloud Run, Render, Railway e Heroku injetam PORT; o serviço lê SERVER_PORT.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null "http://127.0.0.1:${PORT:-$SERVER_PORT}/health/ready" || exit 1
ENTRYPOINT ["/bin/sh", "-c", "SERVER_PORT=\"${PORT:-$SERVER_PORT}\" exec /app/danfse-service"]
