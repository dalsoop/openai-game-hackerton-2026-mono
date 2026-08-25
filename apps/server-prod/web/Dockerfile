# 빌드 컨텍스트는 슬롯 루트(apps/server-yjh-dev1). Next+허브가 한 프로세스다.
FROM node:22-alpine AS build
WORKDIR /app
COPY web/package.json web/package-lock.json ./
RUN npm ci
COPY web/ ./
COPY project/addons/colyseus/bin ./public/addons/colyseus/bin
RUN npx next build && npx tsc --project tsconfig.server.json

FROM node:22-alpine
WORKDIR /app
COPY web/package.json web/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/dist ./dist
COPY --from=build /app/public ./public
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE 8080
CMD ["node", "dist/server.js"]
