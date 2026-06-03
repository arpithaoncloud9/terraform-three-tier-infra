# Use official Node.js lightweight image
FROM node:22-alpine

# Set working directory inside the container
WORKDIR /app

# Copy dependency files first (better caching)
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the rest of the app code
COPY . .

# Expose the port the app listens on
EXPOSE 3000

# Start the app
CMD ["node", "server.js"]