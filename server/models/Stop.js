const mongoose = require("mongoose");

const stopSchema = new mongoose.Schema({
  stopName: { type: String, required: true },
  location: {
    type: { type: String, default: "Point" },
    coordinates: { type: [Number], required: true } // [longitude, latitude]
  },
  routeId: { type: mongoose.Schema.Types.ObjectId, ref: "Route" },
  pickupTime: { type: String }, // e.g., "08:30 AM"
  dropTime: { type: String }
}, { timestamps: true });

// Index for geospatial queries
stopSchema.index({ location: "2dsphere" });

module.exports = mongoose.model("Stop", stopSchema);
