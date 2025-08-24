FROM node:20

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm install -g @quasar/cli

COPY . .

EXPOSE 9000

CMD ["quasar", "dev"]
