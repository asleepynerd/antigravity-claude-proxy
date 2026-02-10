# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install build dependencies if needed for native modules
RUN apk add --no-cache python3 make g++

# Copy source files first so prepare script (post-install) can run build:css
COPY . .

# Install dependencies and run prepare script
RUN npm install

# Rebuild dependencies (for native modules like better-sqlite3) - explicit rebuild sometimes helps on alpine
RUN npm rebuild

# Remove devDependencies to keep image small
RUN npm prune --production

# Runtime stage
FROM node:22-alpine

WORKDIR /app

# Copy built artifacts and production dependencies
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/src ./src
COPY --from=builder /app/public ./public
COPY --from=builder /app/bin ./bin

# Create config directory for persistence
# Running as root by default allows easy volume mapping on host
RUN mkdir -p /root/.config/antigravity-proxy

ENV NODE_ENV=production
ENV PORT=8080

EXPOSE 8080

CMD ["npm", "start"]
