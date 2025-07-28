FROM mcr.microsoft.com/playwright:v1.54.0-noble
USER root
RUN npm cache clean --force
USER pwuser
RUN npm install -g netlify-cli node-jq
