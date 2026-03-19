# 🐳 Deploying with Docker Compose

This setup uses Docker Compose to orchestrate the MongoDB, Server, and Client containers for local development.

---

## 📋 Prerequisites

- Docker and Docker Desktop installed.
- Create the external volume for MongoDB persistence:

```bash
docker volume create mongodb
```

---

## 🚀 Getting Started

### 1. Configure Environment Variables

Ensure `server/.env` and `client/.env` exist with the correct variables.

**`server/.env` example:**
```env
PORT=5000
MONGO_URI=mongodb://mongodb:27017/mydb
```

**`client/.env` example:**
```env
VITE_API_URL=http://localhost:5000
```

### 2. Build and Run

```bash
docker-compose up --build
```

### 3. Access the Application

| Service      | URL                        |
|--------------|----------------------------|
| Frontend     | http://localhost:5173       |
| Backend API  | http://localhost:5000       |
| MongoDB      | `localhost:27017`           |

---

## 🔄 Services

| Service | Image                        | Port  |
|---------|------------------------------|-------|
| MongoDB | `mongodb-community-server`   | 27017 |
| Server  | `hashimaliii/server:v1.0`    | 5000  |
| Client  | `hashimaliii/client:v1.0`    | 5173  |

---

## 🛑 Stopping the Stack

```bash
# Stop containers (preserves volumes)
docker-compose down

# Stop and remove volumes (destructive!)
docker-compose down -v
```

---

## 🛠️ Useful Commands

```bash
# View running containers
docker ps

# Follow server logs
docker-compose logs -f server

# Access MongoDB shell
docker exec -it <mongo-container-name> mongosh

# Rebuild a single service
docker-compose up --build server
```

---

## 📁 Volume

MongoDB data is persisted using an **external named volume** (`mongodb`). This volume must be created manually before running the stack. It survives `docker-compose down` but is removed by `docker-compose down -v`.

```bash
# Inspect the volume
docker volume inspect mongodb
```
