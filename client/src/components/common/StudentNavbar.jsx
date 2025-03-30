import { Link } from 'react-router-dom';
import '../../assets/css/navbar.css';

export default function StudentNavbar() {
    return (
        <nav className="student-navbar">
            <Link to="/student/dashboard">Tutor Search</Link>
            <Link to="/student/sessions">My Sessions</Link>
            <Link to="/student/wishlist">My Wishlist</Link>
            <Link to="/student/notifications">Notifications</Link>
        </nav>
    );
}
