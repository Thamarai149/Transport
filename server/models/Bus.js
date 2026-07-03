const mongoose = require("mongoose");

const busSchema = new mongoose.Schema({
  busNumber: { type: String, required: true, unique: true },
  registrationNumber: { type: String, required: true, unique: true },
  capacity: { type: Number, required: true },
  assignedDriver: { type: mongoose.Schema.Types.ObjectId, ref: "Driver" },
  currentRoute: { type: mongoose.Schema.Types.ObjectId, ref: "Route" },
  status: { 
    type: String, 
    enum: ["Active", "Maintenance", "Inactive"],
    default: "Active" 
  },
  insuranceExpiry: { type: Date },
  lastMaintenance: { type: Date }
}, { timestamps: true });

module.exports = mongoose.model("Bus", busSchema);
