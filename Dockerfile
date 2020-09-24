FROM alpine:3.7
COPY build/vgb-linux-x64 .

ENTRYPOINT [ "vgb-linux-x64" ]