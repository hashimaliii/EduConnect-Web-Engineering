# 🌐 EduConnect Pakistan – Frontend

This is the **frontend application** of the **EduConnect Pakistan** platform – a MERN-based system designed to connect students with tutors. Built with **React (Vite)**, the platform supports three types of users: **Students**, **Tutors**, and **Admins**, offering a responsive, user-friendly experience for all.

---

## 🚀 Features

### 👨‍🎓 Student
- 🔍 Search tutors by subject, city, rating, price, and availability
- 📌 Add tutors to wishlist
- 📅 Book, reschedule, and cancel sessions
- ✍️ Leave reviews and ratings
- 📈 View booked sessions and wishlist

### 👨‍🏫 Tutor
- 📝 Manage tutor profile and availability calendar
- 📤 Submit verification documents
- ✅ Accept or decline session bookings
- 💵 Track session earnings

### 🛡️ Admin
- 📊 Dashboard with overall stats
- ✅ View and manage tutor verifications
- 👥 View/delete users
- 📈 Access user, subject & session reports

---

## 🛠️ Tech Stack

| Layer        | Tech                        |
|--------------|-----------------------------|
| Frontend     | React + Vite                |
| Styling      | Simple CSS (light theme)    |
| Routing      | React Router DOM            |
| HTTP Client  | Axios                       |
| State Mgmt   | useState, useEffect (React) |

---

## 📁 Project Structure

```
client/
├── public/
├── src/
│   ├── assets/
│   │   ├── css/
│   │   └── icons/
│   ├── components/
│   │   ├── common/
│   │   ├── reviews/
│   │   ├── sessions/
│   │   ├── tutors/
│   │   ├── wishlist/
│   ├── context/
│   ├── hooks/
│   ├── pages/
│   │   ├── auth/
│   │   ├── student/
│   │   ├── tutor/
│   │   ├── admin/
│   ├── utils/
│   └── main.jsx
```

---

## ⚙️ Setup & Installation

1. Clone the repository:

```bash
git clone https://github.com/your-username/educonnect-frontend.git
cd educonnect-frontend
```

2. Install dependencies:

```bash
npm install
```

3. Create a `.env` file in the root of the project:

```env
VITE_API_URL=http://localhost:5000
```

4. Run the development server:

```bash
npm run dev
```

The app will start at `http://localhost:5173`.

---

## 📬 API Reference

All API requests are made to the backend hosted at:

```
http://localhost:5000/api
```

Ensure your backend server is running before interacting with the frontend.

---

## ✅ Status

✅ Fully functional Student, Tutor, and Admin flows  
🚀 Bonus: Tutor Availability Calendar included  
📌 UI: Light-themed, clean interface

---

## 📄 License

This project is part of a university Web Engineering course assignment and is meant for academic use.