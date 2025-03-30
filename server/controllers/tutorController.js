const User = require('../models/User');

const searchTutors = async (req, res) => {
    const { subject, city, priceMin, priceMax, rating, availability } = req.query;

    let query = { role: 'tutor' };

    if (subject) {
        query.subjects = { $regex: subject, $options: 'i' };
    }

    if (city) {
        query.city = { $regex: city, $options: 'i' };
    }

    if (priceMin || priceMax) {
        query.hourlyRate = {};
        if (priceMin) query.hourlyRate.$gte = Number(priceMin);
        if (priceMax) query.hourlyRate.$lte = Number(priceMax);
    }

    if (rating) {
        query.averageRating = { $gte: Number(rating) };
    }

    if (availability) {
        query.availability = { $in: [availability] };
    }

    try {
        const tutors = await User.find(query).select('-password');
        res.json(tutors);
    } catch (err) {
        res.status(500).json({ message: 'Server Error' });
    }
};

// GET /api/tutors/profile
const getTutorProfile = async (req, res) => {
    const tutor = await User.findById(req.user._id).select('-password');
    res.json(tutor);
};

// PUT /api/tutors/profile
const updateTutorProfile = async (req, res) => {
    const {
        name,
        bio,
        qualifications,
        subjects,
        hourlyRate,
        availability,
        teachingPreferences,
        profileImage
    } = req.body;

    try {
        const tutor = await User.findById(req.user._id);
        if (!tutor) return res.status(404).json({ message: 'Tutor not found' });

        // Update only if values provided
        if (name) tutor.name = name;
        if (bio) tutor.bio = bio;
        if (qualifications) tutor.qualifications = qualifications;
        if (subjects) tutor.subjects = subjects;
        if (hourlyRate) tutor.hourlyRate = hourlyRate;
        if (availability) tutor.availability = availability;
        if (teachingPreferences) tutor.teachingPreferences = teachingPreferences;
        if (profileImage) tutor.profileImage = profileImage;

        const updatedTutor = await tutor.save();
        res.json(updatedTutor);
    } catch (err) {
        res.status(500).json({ message: 'Server error' });
    }
};

module.exports = {
    getTutorProfile,
    updateTutorProfile,
    searchTutors
};
