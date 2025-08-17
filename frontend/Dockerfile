FROM node:20

WORKDIR /app

COPY package*.json ./
COPY . .

RUN npm install
RUN npm install -g @quasar/cli

EXPOSE 9000

CMD [ "quasar", "dev" ]