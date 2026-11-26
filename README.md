# gerador-danfse-docker

> **Projeto não oficial.** Mantido pela NFE.io, sem vínculo com a Receita Federal.
> O código do serviço é o oficial da Receita; este repositório só empacota e facilita o deploy.

Imagem Docker pronta do **DANFSe Service** da Receita Federal
([ReceitaFederal/calculadora-rtc-gerador-danfse](https://github.com/ReceitaFederal/calculadora-rtc-gerador-danfse), licença MIT).
O serviço recebe o XML da NFS-e nacional e devolve o DANFSe em PDF.

Este repositório não copia o código da Receita. O `Dockerfile` baixa o código
oficial em um commit fixo (`UPSTREAM_REF`), aplica correções de segurança de
dependências, roda os testes oficiais e compila.

## Rodar em 1 minuto

```bash
docker run --rm -p 8080:8080 ghcr.io/nfe/gerador-danfse-docker:latest
# exemplos/nfse-sintetica.xml é uma NFS-e fictícia (fixture dos testes oficiais)
curl -H 'Content-Type: application/xml' --data-binary @exemplos/nfse-sintetica.xml \
  'http://localhost:8080/api/danfse?stc=0&canhoto=true' -o danfse.pdf
```

Swagger: <http://localhost:8080/api/swagger-ui/>. Health: `/health/live` e `/health/ready`.

Ou com Compose: `docker compose up -d`.

## Deploy com um clique

| Nuvem | Botão | Observação |
| --- | --- | --- |
| Cloudflare | [![Deploy to Cloudflare](https://deploy.workers.cloudflare.com/button)](https://deploy.workers.cloudflare.com/?url=https://github.com/nfe/gerador-danfse-docker) | Workers Paid (US$ 5/mês). Worker + Container. |
| Render | [![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/nfe/gerador-danfse-docker) | Plano free; dorme sem tráfego. |
| Google Cloud Run | [![Run on Google Cloud](https://deploy.cloud.run/button.svg)](https://deploy.cloud.run?git_repo=https://github.com/nfe/gerador-danfse-docker) | Escala a zero. |

Outras plataformas usam a imagem direto:

```bash
fly launch --image ghcr.io/nfe/gerador-danfse-docker:latest --internal-port 8080   # Fly.io
az containerapp up -n danfse --image ghcr.io/nfe/gerador-danfse-docker:latest --ingress external --target-port 8080   # Azure
```

Railway, Koyeb e Kubernetes: aponte para `ghcr.io/nfe/gerador-danfse-docker:latest`, porta `8080`,
probe HTTP em `/health/ready`.

## Configuração

| Variável | Padrão | Descrição |
| --- | --- | --- |
| `PORT` / `SERVER_PORT` | `8080` | Porta HTTP. `PORT` (injetada pelas nuvens) tem prioridade. |
| `LOG_LEVEL` | `info` | `debug`, `info`, `warn`, `error`. |
| `XML_MAX_SIZE_BYTES` | `5242880` | Tamanho máximo do XML (teto 32 MiB). |
| `OTEL_*` | desligado | Tracing OTLP opcional; veja o README oficial. |

## Segurança

- A imagem roda como usuário não-root (`65532`), sem estado e sem disco gravável.
- O serviço não grava nem loga o XML ou o PDF.
- **O endpoint não tem autenticação.** O XML contém dados fiscais do tomador e do
  prestador. Em deploy público, proteja o acesso (Cloudflare Access, IAM do Cloud Run,
  rede privada).
- Cada imagem passa por scan Trivy e sai com SBOM e atestado de proveniência.

## Licença e atribuição

Código do serviço: © Receita Federal do Brasil, MIT (ver `/app/LICENSE.upstream` na imagem).
Empacotamento (Dockerfile, deploy, CI): © NFE.io, MIT.
Este projeto não é oficial e não tem vínculo com a Receita Federal.
