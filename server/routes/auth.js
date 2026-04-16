const express = require('express');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { sendSmtpMail } = require('../lib/smtp');

const router = express.Router();

// SIGN UP
router.post('/signup', async (req, res) => {
  try {
    const { name, email, company, designation, password } = req.body;

    if (!name || !email || !company || !designation || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists' });
    }

    const user = new User({
      name: String(name).trim(),
      email: normalizedEmail,
      company: String(company).trim(),
      designation: String(designation).trim(),
      password,
    });
    await user.save();

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET || 'secret_key', { expiresIn: '7d' });
    res.status(201).json({
      token,
      user: {
        name: user.name,
        email: user.email,
        company: user.company,
        designation: user.designation,
      },
    });
  } catch (err) {
    if (err && err.code === 11000) {
      return res.status(409).json({ message: 'User already exists' });
    }
    if (err && err.name === 'ValidationError') {
      return res.status(400).json({ message: err.message });
    }
    res.status(500).json({ message: err.message });
  }
});

// LOGIN
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid email or password' });
    }

    const token = jwt.sign({ userId: user._id }, process.env.JWT_SECRET || 'secret_key', { expiresIn: '7d' });
    res.json({ token, user: { name: user.name, email: user.email, company: user.company, designation: user.designation } });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// FORGOT PASSWORD
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;
    const normalizedEmail = String(email || '').trim().toLowerCase();
    const user = await User.findOne({ email: normalizedEmail });
    if (!user) return res.status(404).json({ message: 'User not found' });

    const resetToken = crypto.randomBytes(32).toString('hex');
    user.resetToken = crypto.createHash('sha256').update(resetToken).digest('hex');
    user.resetTokenExpiry = Date.now() + 3600000; // 1 hour
    await user.save();

    const htmlContent = `
      <h1>Password Reset</h1>
      <p>You requested a password reset. Please use the following token to reset your password:</p>
      <p><strong>${resetToken}</strong></p>
      <p>This token will expire in 1 hour.</p>
    `;

    await sendSmtpMail({
      to: normalizedEmail,
      subject: 'Daily Check - Password Reset',
      html: htmlContent,
    });

    res.json({ message: 'Reset token sent to email' });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
