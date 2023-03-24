# Start by building the application.
FROM golang:1.19-alpine as build

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
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -ldflags="-w -s" -o /go/bin/app.bin cmd/main.go

# Now copy it into our base image.
FROM gcr.io/distroless/base-debian11


COPY --from=build /bin/sh /bin/sh
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/group /etc/group
COPY --from=build /go/bin/app.bin /app.bin

USER appuser:appuser

CMD /app.bin -port=${APP_PORT} -host=${APP_HOST} -dbUrl=${DB_URL}
