FROM node:22-alpine AS builder

WORKDIR /app
# 新增：git / make / g++ / cmake / python3，並裝 libc6-compat 以避免常見的 GLIBC 相容性問題
RUN apk add --no-cache git make g++ cmake python3 libc6-compat

COPY package*.json ./

# 建議關掉 husky 等 git hook（容器內通常沒有 .git）
ENV HUSKY=0
RUN npm ci

COPY . .
RUN npm run build

FROM node:22-alpine AS runner

WORKDIR /app

# Install curl for health checks
RUN apk add --no-cache curl

# Install production dependencies
COPY package*.json ./
RUN npm ci --production && npm cache clean --force

# Copy built application
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S sveltekit -u 1001
USER sveltekit

EXPOSE 3000

ENV NODE_ENV=production
ENV PORT=3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

CMD ["node", "build"]
