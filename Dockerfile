FROM ubuntu:20.04 AS build-env
WORKDIR /build

# Copy the project folder
COPY VirtualGloomhavenBoard/. .

# Install required programs
RUN apt-get update -yq \
    && apt-get -yq install curl gnupg ca-certificates \
    && curl -L https://deb.nodesource.com/setup_12.x | bash \
    && apt-get update -yq \
    && apt-get install -yq \
        nodejs \
        curl

# Install Elm
RUN curl -L -o elm.gz https://github.com/elm/compiler/releases/download/0.19.1/binary-for-linux-64-bit.gz
RUN gunzip elm.gz
RUN chmod +x elm
RUN mv elm /usr/local/bin/

# Install Node.js commands
RUN npm -g install uglify-js
RUN npm -g install sass

# Install .Net Core
RUN curl -L -o dotnet.deb https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb
RUN dpkg -i dotnet.deb
RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y dotnet-sdk-3.1

# Build the app
RUN dotnet publish -c Release --self-contained true -r linux-x64 -o ./publish

# Copy the app to a minimul Linux build
FROM ubuntu:20.04
EXPOSE 5000
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1

RUN apt-get update; \
    apt-get install -y apt-transport-https && \
    apt-get update && \
    apt-get install -y libssl1.1


COPY --from=build-env /build/publish ./app
ENTRYPOINT ["./app/VirtualGloomhavenBoard"]