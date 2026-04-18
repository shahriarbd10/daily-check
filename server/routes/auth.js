const express = require('express');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const User = require('../models/User');
const { sendSmtpMail } = require('../lib/smtp');

const router = express.Router();

function requireAuth(req, res, next) {
  try {
    const authHeader = req.headers.authorization || '';
    const token = authHeader.startsWith('Bearer ')
      ? authHeader.slice(7)
      : null;

    if (!token) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const payload = jwt.verify(token, process.env.JWT_SECRET || 'secret_key');
    req.userId = payload.userId;
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
}

// SIGN UP
router.post('/signup', async (req, res) => {
  try {
    const { name, email, company, designation, password, officeStartTime, officeEndTime } = req.body;

    if (!name || !email || !company || !designation || !password) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const normalizedEmail = String(email).trim().toLowerCase();
    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(409).json({ message: 'User already exists' });
    }

    const normalizedOfficeStart = /^\d{2}:\d{2}$/.test(String(officeStartTime || ''))
      ? String(officeStartTime)
      : '08:15';
    const normalizedOfficeEnd = /^\d{2}:\d{2}$/.test(String(officeEndTime || ''))
      ? String(officeEndTime)
      : '18:00';

    const user = new User({
      name: String(name).trim(),
      email: normalizedEmail,
      company: String(company).trim(),
      designation: String(designation).trim(),
      officeStartTime: normalizedOfficeStart,
      officeEndTime: normalizedOfficeEnd,
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
        officeStartTime: user.officeStartTime,
        officeEndTime: user.officeEndTime,
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
    res.json({
      token,
      user: {
        name: user.name,
        email: user.email,
        company: user.company,
        designation: user.designation,
        officeStartTime: user.officeStartTime || '08:15',
        officeEndTime: user.officeEndTime || '18:00',
      },
    });
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

// GET PROFILE
router.get('/profile', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.userId).select(
      'name email company designation officeStartTime officeEndTime',
    );
    if (!user) return res.status(404).json({ message: 'User not found' });

    return res.json({ user });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

// UPDATE PROFILE
router.put('/profile', requireAuth, async (req, res) => {
  try {
    const { name, company, designation, officeStartTime, officeEndTime } = req.body;

    if (!name || !company || !designation) {
      return res.status(400).json({ message: 'All fields are required' });
    }

    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    user.name = String(name).trim();
    user.company = String(company).trim();
    user.designation = String(designation).trim();
    if (officeStartTime != null) {
      const value = String(officeStartTime).trim();
      if (!/^\d{2}:\d{2}$/.test(value)) {
        return res.status(400).json({ message: 'officeStartTime must be HH:mm' });
      }
      user.officeStartTime = value;
    }
    if (officeEndTime != null) {
      const value = String(officeEndTime).trim();
      if (!/^\d{2}:\d{2}$/.test(value)) {
        return res.status(400).json({ message: 'officeEndTime must be HH:mm' });
      }
      user.officeEndTime = value;
    }
    await user.save();

    return res.json({
      message: 'Profile updated successfully',
      user: {
        name: user.name,
        email: user.email,
        company: user.company,
        designation: user.designation,
        officeStartTime: user.officeStartTime,
        officeEndTime: user.officeEndTime,
      },
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

// SAVE DAILY HABIT REPORT
router.put('/habit-report', requireAuth, async (req, res) => {
  try {
    const { dateKey, checkedHabitIds, totalHabits, isOffDay } = req.body;
    const normalizedDateKey = String(dateKey || '').trim();
    const total = Number(totalHabits || 0);
    const offDay = Boolean(isOffDay);

    if (!/^\d{4}-\d{2}-\d{2}$/.test(normalizedDateKey)) {
      return res.status(400).json({ message: 'Invalid dateKey format' });
    }
    if (!Array.isArray(checkedHabitIds)) {
      return res.status(400).json({ message: 'checkedHabitIds must be an array' });
    }
    if (!Number.isFinite(total) || total <= 0) {
      return res.status(400).json({ message: 'totalHabits must be greater than 0' });
    }

    const uniqueChecked = [...new Set(checkedHabitIds.map((v) => String(v).trim()).filter(Boolean))];
    const completionRate = offDay
      ? 0
      : Math.min(1, Math.max(0, uniqueChecked.length / total));

    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const existingIndex = user.habitReports.findIndex((h) => h.dateKey === normalizedDateKey);
    const payload = {
      dateKey: normalizedDateKey,
      checkedHabitIds: offDay ? [] : uniqueChecked,
      completionRate,
      isOffDay: offDay,
      updatedAt: new Date(),
    };

    if (existingIndex >= 0) {
      user.habitReports[existingIndex] = payload;
    } else {
      user.habitReports.push(payload);
    }

    user.habitReports = user.habitReports
      .sort((a, b) => a.dateKey.localeCompare(b.dateKey))
      .slice(-180);

    await user.save();

    return res.json({
      message: 'Habit report saved',
      report: payload,
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

// GET MONTHLY HABIT ANALYTICS
router.get('/habit-report/monthly', requireAuth, async (req, res) => {
  try {
    const monthParam = String(req.query.month || '').trim();
    const now = new Date();
    const fallbackMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
    const targetMonth = /^\d{4}-\d{2}$/.test(monthParam) ? monthParam : fallbackMonth;

    const user = await User.findById(req.userId).select('habitReports');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const monthReports = (user.habitReports || [])
      .filter((h) => typeof h.dateKey === 'string' && h.dateKey.startsWith(`${targetMonth}-`))
      .sort((a, b) => a.dateKey.localeCompare(b.dateKey));

    const offDayReports = monthReports.filter((item) => Boolean(item.isOffDay));
    const normalReports = monthReports.filter((item) => !Boolean(item.isOffDay));
    const totalDays = normalReports.length;
    const averageRate = totalDays === 0
      ? 0
      : normalReports.reduce((sum, item) => sum + Number(item.completionRate || 0), 0) / totalDays;

    const bestRate = totalDays === 0
      ? 0
      : Math.max(...normalReports.map((item) => Number(item.completionRate || 0)));

    const streak = (() => {
      let count = 0;
      for (let i = monthReports.length - 1; i >= 0; i--) {
        if (Boolean(monthReports[i].isOffDay)) {
          continue;
        }
        const rate = Number(monthReports[i].completionRate || 0);
        if (rate >= 0.8) {
          count += 1;
        } else {
          break;
        }
      }
      return count;
    })();

    return res.json({
      month: targetMonth,
      summary: {
        averageRate,
        bestRate,
        daysReported: totalDays,
        offDays: offDayReports.length,
        eliteDays: normalReports.filter((item) => Number(item.completionRate || 0) >= 0.85).length,
        currentStreak: streak,
      },
      days: monthReports.map((item) => ({
        dateKey: item.dateKey,
        completionRate: Number(item.completionRate || 0),
        checkedCount: Array.isArray(item.checkedHabitIds) ? item.checkedHabitIds.length : 0,
        checkedHabitIds: Array.isArray(item.checkedHabitIds) ? item.checkedHabitIds : [],
        isOffDay: Boolean(item.isOffDay),
      })),
    });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
});

module.exports = router;
