FROM mcr.microsoft.com/dotnet/core/sdk:3.1 AS build-env

WORKDIR /build
COPY VirtualGloomhavenBoard/. .

RUN dotnet publish -c Release --self-contained true -r linux-musl-x64 VirtualGloomhavenBoard -o /publish/

FROM alpine:3.7
WORKDIR /app
COPY --from=build-env /publish .
ENTRYPOINT ["VirtualGloomhavenBoard"]