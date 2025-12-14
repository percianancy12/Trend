FROM nginx:alpine

# Copy React dist folder into Nginx HTML directory
COPY dist /usr/share/nginx/html

# Expose port 80 (Nginx default)
EXPOSE 80

# Run Nginx
CMD ["nginx", "-g", "daemon off;"]