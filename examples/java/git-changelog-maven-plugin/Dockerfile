FROM maven:3.9-eclipse-temurin-21-alpine

RUN apk add --no-cache git bash

WORKDIR /work

COPY app/ ./app/
COPY scenario/ ./scenario/
COPY run_experiment.sh ./run_experiment.sh
RUN chmod +x ./run_experiment.sh

RUN mkdir -p /work/out

CMD ["./run_experiment.sh"]
