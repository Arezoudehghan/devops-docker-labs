FROM golang:1.25-alpine AS builder

WORKDIR /src

COPY go.mod ./
COPY main.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o app .


FROM alpine:3.22

WORKDIR /app

COPY --from=builder /src/app ./app

EXPOSE 8080

CMD ["./app"]
