# syntax=docker/dockerfile:1

FROM alpine:3.20

RUN --mount=type=secret,id=build_token \
    test -s /run/secrets/build_token && \
    echo "Build secret received successfully"

CMD ["sh", "-c", "sleep 3600"]
