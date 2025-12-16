# Stage 1: Dependencies
FROM oven/bun:1-alpine AS deps

WORKDIR /app

COPY package.json bun.lock ./

RUN bun install --frozen-lockfile --production

FROM oven/bun:1-alpine AS builder

WORKDIR /app

COPY package.json bun.lock ./

RUN bun install --frozen-lockfile

COPY . .

RUN bun run build

FROM nginx:alpine-slim AS runtime

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder --chown=appuser:appgroup /app/dist /usr/share/nginx/html

RUN chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    chown -R appuser:appgroup /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown -R appuser:appgroup /var/run/nginx.pid

USER appuser

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
