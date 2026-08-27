# 빌드 컨텍스트는 슬롯 루트(apps/server-prod). Next+허브가 한 프로세스다.
# ship 이 같은 태그를 건너뛰지 않게 한다. 2026-08-26 tsc-alias.
FROM node:22-alpine AS build
WORKDIR /app
COPY web/package.json ./
COPY web/package-lock.json ./
RUN test -s package-lock.json && grep -q '"lockfileVersion"' package-lock.json
RUN npm ci
COPY web/ ./
RUN test -n "$(find public/godot -name index.pck -print -quit)" \
  || (echo "godot pack missing — Apps ship 이 godot:build+publish 뒤에 이 이미지를 굽는다" && exit 1)
# --link 심링크를 구우면 이미지 안에 project/web 이 없어 엔진이 404 가 난다.
RUN if [ -n "$(find public/godot -type l -print -quit)" ]; then \
      echo "godot public assets are symlinks — npm run godot:publish (copy, not --link)" >&2; \
      exit 1; \
    fi
ENV HACKERTONE_IMAGE_BUILD=1
RUN npx next build
RUN npx tsc --project tsconfig.server.json
RUN npx --yes tsc-alias@1.8.16 -p tsconfig.server.json
RUN node scripts/rewrite-dist-aliases.mjs
RUN ! grep -RE 'require\(["'"'"']@/' dist || (echo "alias require remains in dist" && exit 1)

FROM node:22-alpine
WORKDIR /app
COPY web/package.json ./
COPY web/package-lock.json ./
RUN test -s package-lock.json && grep -q '"lockfileVersion"' package-lock.json
RUN npm ci --omit=dev
COPY --from=build /app/.next ./.next
COPY --from=build /app/dist ./dist
COPY --from=build /app/public ./public
ENV NODE_ENV=production
ENV PORT=8080
ENV DAGUL_SKILLS=on
EXPOSE 8080
CMD ["node", "-r", "./dist/alias-register.js", "dist/server.js"]
