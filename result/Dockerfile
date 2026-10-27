FROM node:18-slim@sha256:f9ab18e354e6855ae56ef2b290dd225c1e51a564f87584b9bd21dd651838830e

# add curl for healthcheck
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y && \
    apt-get install -y --no-install-recommends curl tini && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user and group
RUN groupadd --gid 10001 appgroup && \
    useradd --uid 10001 --gid appgroup --shell /usr/sbin/nologin --no-create-home appuser

WORKDIR /usr/local/app

# have nodemon available for local dev use (file watching)
RUN npm install -g nodemon

COPY package*.json ./

RUN npm ci && \
 npm cache clean --force && \
 mv /usr/local/app/node_modules /node_modules

COPY --chown=appuser:appgroup . .

# Give the non-root user ownership of the app and node_modules
RUN chown -R appuser:appgroup /usr/local/app /node_modules

ENV PORT=8080
EXPOSE 8080

# Switch to the non-root user
USER 10001

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["node", "server.js"]
