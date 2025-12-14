FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom config (must be in repo root)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy React dist folder into Nginx HTML directory
COPY dist /usr/share/nginx/html

# Expose port 80 (Nginx default)
EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]