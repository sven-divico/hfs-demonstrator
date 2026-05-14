FROM node:22-alpine

# better-sqlite3 needs build tools at install time
RUN apk add --no-cache python3 make g++

WORKDIR /app

# Install deps separately for layer caching
COPY package*.json ./
RUN npm ci --omit=dev

# App sources
COPY tsconfig.json ./
COPY server ./server
COPY scripts ./scripts
COPY db ./db
COPY public ./public

# tsx is needed at runtime (we run TS directly, no build step)
RUN npm install -g tsx@4

ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080

CMD ["tsx", "server/index.ts"]
