FROM tensorflow/tensorflow:1.14.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    g++ \
		gcc \
		libc6-dev \
		make \
		pkg-config \
    wget \
    git \
	&& rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.12.9

# Install TensorFlow C library
RUN curl -L \
   "https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-cpu-linux-x86_64-1.14.0.tar.gz" | \
   tar -C "/usr/local" -xz
RUN ldconfig

# Hide some warnings
ENV TF_CPP_MIN_LOG_LEVEL 2

# Install Go
# https://github.com/docker-library/golang/blob/221ee92559f2963c1fe55646d3516f5b8f4c91a4/1.9/stretch/Dockerfile

RUN set -eux; \
	\
# this "case" statement is generated via "update.sh"
	dpkgArch="$(dpkg --print-architecture)"; \
	case "${dpkgArch##*-}" in \
		amd64) goRelArch='linux-amd64'; goRelSha256='ac2a6efcc1f5ec8bdc0db0a988bb1d301d64b6d61b7e8d9e42f662fbb75a2b9b' ;; \
		armhf) goRelArch='linux-armv6l'; goRelSha256='0d9be0efa9cd296d6f8ab47de45356ba45cb82102bc5df2614f7af52e3fb5842' ;; \
		arm64) goRelArch='linux-arm64'; goRelSha256='98a42b9b8d3bacbcc6351a1e39af52eff582d0bc3ac804cd5a97ce497dd84026' ;; \
		i386) goRelArch='linux-386'; goRelSha256='e74f2f37b43b9b1bcf18008a11e0efb8921b41dff399a4f48ac09a4f25729881' ;; \
		ppc64el) goRelArch='linux-ppc64le'; goRelSha256='23291935a299fdfde4b6a988ce3faa0c7a498aab6d56bbafbf1e7476468529a3' ;; \
		s390x) goRelArch='linux-s390x'; goRelSha256='a67ef820ef8cfecc8d68c69dd5bf513aaf647c09b6605570af425bf5fe8a32f0' ;; \
		*) goRelArch='src'; goRelSha256='ab0e56ed9c4732a653ed22e232652709afbf573e710f56a07f7fdeca578d62fc'; \
			echo >&2; echo >&2 "warning: current architecture ($dpkgArch) does not have a corresponding Go binary release; will be building from source"; echo >&2 ;; \
	esac; \
	\
	url="https://golang.org/dl/go${GOLANG_VERSION}.${goRelArch}.tar.gz"; \
	wget -O go.tgz "$url"; \
	echo "${goRelSha256} *go.tgz" | sha256sum -c -; \
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ "$goRelArch" = 'src' ]; then \
		echo >&2; \
		echo >&2 'error: UNIMPLEMENTED'; \
		echo >&2 'TODO install golang-any from jessie-backports for GOROOT_BOOTSTRAP (and uninstall after build)'; \
		echo >&2; \
		exit 1; \
	fi; \
	\
	export PATH="/usr/local/go/bin:$PATH"; \
	go version

ENV GOPATH /go
ENV GO112MODULE=on
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"

RUN go get github.com/julienschmidt/httprouter && go get github.com/tensorflow/tensorflow/tensorflow/go

# Set up project directory
WORKDIR "/$GOPATH/src/github.com/revzim/tensr"
COPY go/src . 

COPY models models/

COPY go/src/public go/src/public/

# Install the app
RUN go build -o /usr/bin/app .

# Run the app
# FROM golang:onbuild
# ENTRYPOINT [ "app", "-graphs=models", "-input=Placeholder", "-output=final_result"]

CMD ["app"]
