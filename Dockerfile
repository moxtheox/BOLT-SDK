FROM oven/bun:latest

RUN addgroup --system appgroup && \
    adduser --system --uid 1001 --ingroup appgroup appuser

WORKDIR /app

RUN mkdir -p /app/src

COPY package.json bun.lock ./

# Install dependencies as root
RUN bun install --frozen-lockfile

RUN chown -R appuser:appgroup /app
# Stop using root for the rest of the build
USER appuser

COPY ./src/api ./src/api
COPY index.ts .

EXPOSE 3000
CMD ["bun", "run", "start"]
