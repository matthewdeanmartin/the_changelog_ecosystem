FROM golang:1.24-bookworm

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

# Install via go install — requires go >= 1.24
RUN go install gabe565.com/changelog-generator@v1.1.5

# Ensure the binary is on PATH (go install puts it in $GOPATH/bin = /go/bin)
ENV PATH="/go/bin:${PATH}"

WORKDIR /work

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
