import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/auth/Login';
import Signup from './pages/auth/Signup';
import TutorSearch from './pages/student/TutorSearch';
import MySessions from './pages/student/MySessions';
import Wishlist from './pages/student/Wishlist';
import Notifications from './pages/student/Notifications';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Navigate to="/login" />} />
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/student/dashboard" element={<TutorSearch />} />
        <Route path="/student/sessions" element={<MySessions />} />
        <Route path="/student/wishlist" element={<Wishlist />} />
        <Route path="/student/notifications" element={<Notifications />} />
      </Routes>
    </Router>
  );
}

export default App;
