FROM node:12

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

USER 0

# APK
RUN npm install

RUN echo SESSION_SECRET=EnterYourSecret > ../.tmptenv
RUN echo DATABASE_URL=mongodb://EnterYourUrl:EnterYourPort/subscribers > ../.tmpenv

ENV PORT=4000

USER 1001

EXPOSE 4000

CMD ["npm", "start"] 


