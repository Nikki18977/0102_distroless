# Start by building the application.
FROM golang:1.19-alpine as build
LABEL org.opencontainers.image.source="https://github.com/Nikki18977/0102_distroless"

ENV USER=appuser
ENV UID=10001

RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/bin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    "${USER}"

WORKDIR /go/src/app
COPY /app .

RUN go mod download
RUN go mod verify
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build  -o /go/bin/app.bin cmd/main.go

FROM busybox:1.35.0-uclibc as busybox
FROM gcr.io/distroless/base-debian11

COPY --from=busybox /bin/sh /bin/sh
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /go/bin/app.bin /app.bin

ENV APP_PORT=9000
ENV APP_HOST=0.0.0.0
ENV DB_URL=postgres://user:pass@db:5432/app

USER appuser:appuser

CMD /app.bin -port=${APP_PORT} -host=${APP_HOST} -dbUrl=${DB_URL}

