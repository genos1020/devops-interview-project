FROM nginx:1.25-alpine

# 移除預設設定
RUN rm /etc/nginx/conf.d/default.conf

# 放入我們自己的 nginx 設定
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# 放入網站內容
COPY app/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]