const mongoose = require("mongoose");

const attendanceSchema = new mongoose.Schema({
  student: { type: mongoose.Schema.Types.ObjectId, ref: "Student", required: true },
  trip: { type: mongoose.Schema.Types.ObjectId, ref: "Trip", required: true },
  bus: { type: mongoose.Schema.Types.ObjectId, ref: "Bus" },
  date: { type: Date, default: Date.now },
  status: { 
    type: String, 
    enum: ["Present", "Absent", "Late"],
    default: "Present" 
  },
  scanMethod: { 
    type: String, 
    enum: ["QR Code", "Face Recognition", "Manual", "RFID"],
    default: "QR Code" 
  },
  location: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number] }
  }
}, { timestamps: true });

attendanceSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("Attendance", attendanceSchema);
