ARG ARG_1=$ARG_1
ARG ARG_2=$ARG_2

FROM acr.azurecr.io/app_dependencies:$ARG_1 AS app--build-stage1

WORKDIR /app
RUN ls

FROM node:lts-alpine3.14 AS app--build-stage2
ARG ENV = $ENV
WORKDIR /app
COPY --from=app--build-stage1 /app/node_modules node_modules
COPY . .
RUN npm run ENV


FROM nginx:alpine
WORKDIR /app
COPY --from=app--build-stage2 /app/dist /usr/share/nginx/html
EXPOSE 80
