FROM node:18-alpine AS builder
WORKDIR /app
ARG REACT_APP_VERSION_ARG
ENV REACT_APP_VERSION=$REACT_APP_VERSION_ARG
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM mcr.microsoft.com/playwright:v1.54.0-noble AS runner
WORKDIR /app
USER root
RUN npm install -g netlify-cli@20.1.1
RUN npm install -g serve@14.2.4
RUN npm install -g node-jq
USER pwuser
COPY --from=builder /app/build ./build
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/package-lock.json ./package-lock.json
COPY --from=builder /app/tests ./tests
RUN chown -R pwuser:pwuser /app
WORKDIR /app
CMD ["npm", "start"]