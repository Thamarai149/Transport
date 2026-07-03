const mongoose = require("mongoose");

const studentSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  rollNumber: { type: String, required: true, unique: true },
  college: { type: String, required: true },
  department: { type: String },
  route: { type: mongoose.Schema.Types.ObjectId, ref: "Route" },
  pickupStop: { type: mongoose.Schema.Types.ObjectId, ref: "Stop" },
  qrCode: { type: String }, // URL or hash for the QR
  faceEncoding: { type: Array }, // For AI face recognition
  feeStatus: { type: String, enum: ["Paid", "Pending", "Overdue"], default: "Pending" },
  emergencyContact: { type: String }
}, { timestamps: true });

module.exports = mongoose.model("Student", studentSchema);
