# STAGE 1: Builder
FROM node:20-alpine AS builder
WORKDIR /usr/src/app
COPY package*.json ./
# Install ALL dependencies (including dev tools if needed for build)
RUN npm install
COPY . .
# If you had a build step (like TypeScript or React), it would go here: RUN npm run build

# STAGE 2: Minimal Runtime
FROM node:20-alpine AS runtime
WORKDIR /usr/src/app
# Copy only package files and install strictly production dependencies
COPY package*.json ./
RUN npm install --only=production
# Copy the compiled application from the builder stage
COPY --from=builder /usr/src/app .

# Switch to the non-root 'node' user provided by the alpine image
USER node
EXPOSE 3000
CMD [ "npm", "start" ]