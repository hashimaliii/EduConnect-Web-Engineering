# ☸️ Deploying to Kubernetes (Minikube)

This deployment uses a **StatefulSet** for MongoDB to ensure data persistence and a headless service for stable DNS-based pod discovery.

---

## 🏗️ Deployment Steps

### 1. Start the Database Cluster

Apply the MongoDB StatefulSet and Headless Service:

```bash
kubectl apply -f mongo-ss.yaml
```

Wait until all 3 MongoDB pods are in `Running` state:

```bash
kubectl get pods -w
```

Expected output:
```
NAME      READY   STATUS    RESTARTS   AGE
mongo-0   1/1     Running   0          60s
mongo-1   1/1     Running   0          45s
mongo-2   1/1     Running   0          30s
```

---

### 2. ⚠️ Initialize the MongoDB Replica Set (CRITICAL)

Kubernetes starts the pods, but MongoDB requires a **manual trigger** to form the replica set cluster. Run the following once all 3 pods are `Running`:

```bash
kubectl exec -it mongo-0 -- mongosh --eval "rs.initiate({ _id: 'rs0', members: [{ _id: 0, host: 'mongo-0.mongo:27017' }, { _id: 1, host: 'mongo-1.mongo:27017' }, { _id: 2, host: 'mongo-2.mongo:27017' }] })"
```

Verify the replica set is healthy before proceeding:

```bash
kubectl exec -it mongo-0 -- mongosh --eval "rs.status()"
```

You should see one `PRIMARY` and two `SECONDARY` members.

---

### 3. Deploy App and Client

Once the database is initialized, deploy the rest of the stack:

```bash
kubectl apply -f server.yaml
kubectl apply -f client.yaml
```

---

## 🌐 Accessing the App (Minikube)

`LoadBalancer` services require a tunnel on Minikube. Use one of the following:

```bash
# Open the Frontend directly in your browser
minikube service client-svc

# Get the Backend URL
minikube service server-svc --url
```

Alternatively, start a tunnel in a separate terminal:

```bash
minikube tunnel
```

Then access via `http://localhost` on the configured service port.

---

## 🗂️ File Overview

| File           | Purpose                                           |
|----------------|---------------------------------------------------|
| `mongo-ss.yaml` | MongoDB StatefulSet + Headless Service + PVCs    |
| `server.yaml`  | Server Deployment + ClusterIP/LoadBalancer Service |
| `client.yaml`  | Client Deployment + LoadBalancer Service          |

---

## 🛠️ Debugging Commands

```bash
# List all pods and their status
kubectl get pods

# Check Persistent Volume Claims (storage)
kubectl get pvc

# View server logs
kubectl logs deployment/server

# Stream logs live
kubectl logs -f deployment/server

# Describe a pod for detailed events
kubectl describe pod mongo-0

# Check MongoDB replica set status
kubectl exec -it mongo-0 -- mongosh --eval "rs.status()"

# Drop into a MongoDB shell
kubectl exec -it mongo-0 -- mongosh
```

---

## 🔑 Key Differences vs. Docker Compose

| Concern      | Docker Compose                    | Kubernetes (This Setup)                          |
|--------------|-----------------------------------|--------------------------------------------------|
| Persistence  | Single named volume (`mongodb`)   | 3 separate PVCs (one per StatefulSet pod)         |
| Networking   | Service name (`mongodb`)          | Full DNS via Headless Service (`mongo-0.mongo`)  |
| Scaling      | Manual (`--scale`)                | Declarative replica count in manifests            |
| DB Init      | Automatic on first run            | Manual `rs.initiate()` required                  |

---

## 📌 Notes

- The headless service (created by `mongo-ss.yaml`) gives each pod a stable DNS entry in the format `<pod-name>.<service-name>`. This is how `mongo-0.mongo`, `mongo-1.mongo`, and `mongo-2.mongo` are resolved.
- StatefulPods are started and terminated in **order** (0 → 1 → 2 on start; 2 → 1 → 0 on delete). Always initialize the replica set from `mongo-0`.
- PVCs are **not deleted** when you run `kubectl delete -f mongo-ss.yaml`. Delete them manually if you need a clean slate:

```bash
kubectl delete pvc -l app=mongo
```
