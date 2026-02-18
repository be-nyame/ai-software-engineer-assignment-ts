# Node.js LTS image on Alpine
FROM node:20-alpine

WORKDIR /app

# Copy dependency manifests
COPY package*.json ./

RUN npm install

COPY . .

CMD ["npm", "test"]