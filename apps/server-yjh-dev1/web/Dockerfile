# 다굴 플랫폼 이미지 — custom server(dist/server.js)가 Next.js + WS 허브를 함께 서빙한다.
# 주의: Next 기본 standalone/server.js 는 WS 허브가 없다. 반드시 dist/server.js 를 실행할 것.
# 빌드 전제: scripts/prepare-godot-assets.sh 로 public/godot/dagul 이 실파일로 채워져 있어야 한다.
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
# 계약 게이트(check-contract)는 레포 루트가 필요해 CI 단계에서 돌린다.
RUN npx next build && npx tsc --project tsconfig.server.json

FROM node:22-alpine
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/dist ./dist
COPY --from=build /app/public ./public
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["node", "dist/server.js"]
