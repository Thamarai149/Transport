const mongoose = require("mongoose");

const routeSchema = new mongoose.Schema({
  routeName: { type: String, required: true },
  routeNumber: { type: String, required: true, unique: true },
  startPoint: { type: String, required: true },
  endPoint: { type: String, required: true },
  distance: { type: Number }, // in km
  estimatedTime: { type: Number }, // in minutes
  stops: [{ type: mongoose.Schema.Types.ObjectId, ref: "Stop" }],
  college: { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model("Route", routeSchema);
