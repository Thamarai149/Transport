const mongoose = require("mongoose");

const tripSchema = new mongoose.Schema({
  driver: { type: mongoose.Schema.Types.ObjectId, ref: "Driver", required: true },
  bus: { type: mongoose.Schema.Types.ObjectId, ref: "Bus", required: true },
  route: { type: mongoose.Schema.Types.ObjectId, ref: "Route", required: true },
  startTime: { type: Date },
  endTime: { type: Date },
  status: { 
    type: String, 
    enum: ["Scheduled", "Ongoing", "Completed", "Cancelled"],
    default: "Scheduled" 
  },
  passengerCount: { type: Number, default: 0 },
  startLocation: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number] }
  },
  endLocation: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number] }
  }
}, { timestamps: true });

tripSchema.index({ startLocation: "2dsphere", endLocation: "2dsphere" });

module.exports = mongoose.model("Trip", tripSchema);
