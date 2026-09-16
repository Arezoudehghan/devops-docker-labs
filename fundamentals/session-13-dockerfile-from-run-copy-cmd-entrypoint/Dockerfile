FROM alpine:3.22

RUN mkdir -p /app

COPY hello.sh /app/hello.sh

RUN chmod +x /app/hello.sh

ENTRYPOINT ["/app/hello.sh"]

CMD ["Docker"]
