const mongoose = require("mongoose");

const driverSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  licenseNumber: { type: String, required: true, unique: true },
  licenseExpiry: { type: Date, required: true },
  assignedBus: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  currentRoute: { type: mongoose.Schema.Types.ObjectId, ref: "Route" },
  isActive: { type: Boolean, default: false }, // true when on trip
  behaviorScore: { type: Number, default: 100 } // AI driver behavior analysis
}, { timestamps: true });

module.exports = mongoose.model("Driver", driverSchema);
