FROM node:22-alpine AS build
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
RUN npm ci
COPY backend/tsconfig.json ./
COPY backend/src ./src
RUN npx tsc

FROM node:22-alpine
WORKDIR /app
COPY backend/package.json backend/package-lock.json ./
RUN npm ci --omit=dev
COPY --from=build /app/dist ./dist
COPY frontend ./frontend
ENV PORT=8080
ENV SLOT_FOLDER=server-yjh-dev1
ENV FRONTEND_DIR=./frontend
ENV GAME_SERVER_URL=http://127.0.0.1:9122
ENV LOG_LEVEL=info
ENV PATH_PREFIX=/gang-up
EXPOSE 8080
CMD ["node", "dist/index.js"]
