FROM nginx:1.27-alpine

COPY index.html style.css /usr/share/nginx/html/

EXPOSE 80
