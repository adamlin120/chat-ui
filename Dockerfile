# ---------- Builder ----------
FROM node:22-bookworm-slim AS builder
WORKDIR /app

# 安裝編譯工具與常用套件（供 node-llama-cpp / onnxruntime 等原生模組使用）
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential cmake python3 ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# 避免容器內 husky 嘗試找 .git
ENV HUSKY=0

# 先安裝依賴（利用快取）
COPY package*.json ./
RUN npm ci

# 複製其餘程式碼並建置
COPY . .
RUN npm run build


# ---------- Runner ----------
FROM node:22-bookworm-slim AS runner
WORKDIR /app

# 健康檢查工具
RUN apt-get update && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/*

# 僅安裝 production 依賴
COPY package*.json ./
ENV HUSKY=0
RUN npm ci --omit=dev && npm cache clean --force

# 複製建置產物與必要檔案
COPY --from=builder /app/build ./build
COPY --from=builder /app/package.json ./

# 非 root 執行
RUN groupadd -g 1001 nodejs && useradd -m -u 1001 -g 1001 sveltekit
USER sveltekit

# 環境變數與埠號
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

# 健康檢查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1

# SvelteKit adapter-node 的進入點
CMD ["node", "build/index.js"]
