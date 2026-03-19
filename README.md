# 🎓 EduConnect Pakistan – MERN Stack Platform

**EduConnect Pakistan** is a full-featured online tutoring and session management platform built using the **MERN stack** for university students, tutors, and admins. This system enables seamless session booking, review sharing, and centralized admin control.

---

## 🔗 Live Stack

| Layer     | Tech                             |
|-----------|----------------------------------|
| Frontend  | React (Vite), Axios, CSS         |
| Backend   | Node.js, Express.js              |
| Database  | MongoDB (Mongoose)               |
| Auth      | JWT (JSON Web Tokens)            |

---

## 📦 Project Structure

```
EduConnect-Pakistan/
├── client/     # Frontend (React + Vite)
├── server/     # Backend (Node.js + Express)
├── README.md   # Project Documentation
```

---

## 👥 User Roles & Capabilities

### 👨‍🎓 Students
- Browse tutors by filters (subject, city, availability, rating)
- Book/reschedule/cancel sessions
- Add tutors to wishlist
- Rate and review tutors

### 👨‍🏫 Tutors
- Manage profile, bio, availability, and hourly rate
- Accept/decline/complete booked sessions
- Track earnings
- Submit documents for verification

### 🛡️ Admins
- Approve/reject tutor verification requests
- View/delete user accounts
- Access full platform analytics & reports
- Monitor subjects, session trends, and city-wise growth

---

## ⚙️ Setup Instructions

### 1️⃣ Backend (server/)
```bash
cd server
npm install
# Create .env with:
# MONGO_URI=your_mongodb_connection_string
# JWT_SECRET=your_jwt_secret
npm run dev
```

### 2️⃣ Frontend (client/)
```bash
cd client
npm install
# Create .env with:
# VITE_API_URL=http://localhost:5000
npm run dev
```

### 🧪 Docker Images on HashimAliii
- Client Image: hashimaliii/client:v1.0
- Server Image: hashimaliii/server:v1.0

---

## 🧪 Features

✅ JWT Auth for login/signup  
✅ Tutor availability calendar  
✅ Real-time earnings tracking  
✅ Rate drop notification system  
✅ Admin dashboard & verification system  
✅ Fully responsive UI for all roles  
✅ Bonus reports and analytics

---

## 📁 Highlights of Each Module

### 📂 Frontend (`/client`)
- Built with React + Vite
- Role-based pages under `/pages/student`, `/tutor`, `/admin`
- API interaction using Axios
- Clean custom CSS styling

### 📂 Backend (`/server`)
- Express REST API
- Role-based routing (`/routes/api`)
- Mongoose schemas for User, Session, Review, Verification, etc.
- Middleware for role checks (`protect`, `isTutor`, `isAdmin`, etc.)

---

## 📊 Sample Reports (Admin)

- Session completion rate
- User growth by month
- Top subjects by popularity
- Users by city distribution

---

## 🧾 License

This project is built as part of a university **Web Engineering** course (6th Semester) and is intended for academic use.

---
