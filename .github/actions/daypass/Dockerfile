FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY main.go .
RUN go build -o deployer main.go

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/deployer .
ENTRYPOINT ["/app/deployer"]