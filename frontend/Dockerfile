# Build stage
FROM node:8.17.0-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Runtime stage
FROM node:8.17.0-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies
RUN npm install

# Copy built application and source
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/build ./build
COPY --from=builder /app/config ./config
COPY --from=builder /app/src ./src
COPY --from=builder /app/.eslintrc.js .
COPY --from=builder /app/.eslintignore .
COPY --from=builder /app/.babelrc .
COPY --from=builder /app/.postcssrc.js .
COPY --from=builder /app/index.html .
COPY --from=builder /app/static ./static

# Expose port
EXPOSE 8080

# Run the application
CMD ["npm", "start"]