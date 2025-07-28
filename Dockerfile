FROM mcr.microsoft.com/playwright:v1.54.0-noble
RUN npm install --include=dev netlify-cli node-jq

