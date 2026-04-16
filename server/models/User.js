const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  company: { type: String, required: true },
  designation: { type: String, required: true },
  password: { type: String, required: true },
  resetToken: String,
  resetTokenExpiry: Date,
  habitReports: [
    {
      dateKey: { type: String, required: true },
      checkedHabitIds: { type: [String], default: [] },
      completionRate: { type: Number, default: 0 },
      isOffDay: { type: Boolean, default: false },
      updatedAt: { type: Date, default: Date.now },
    },
  ],
}, { timestamps: true });

// Hash password before saving
userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 12);
});

// Method to compare password
userSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
