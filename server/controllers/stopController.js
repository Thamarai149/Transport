const Stop = require("../models/Stop");

// @desc    Get all stops
// @route   GET /api/stops
// @access  Private
const getStops = async (req, res) => {
  try {
    const stops = await Stop.findAll();
    res.json(stops);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create a stop
// @route   POST /api/stops
// @access  Private/Admin
const createStop = async (req, res) => {
  try {
    // Support both flat {latitude, longitude} and old GeoJSON {location: {coordinates: [lon, lat]}}
    const body = { ...req.body };
    if (body.location && body.location.coordinates) {
      body.longitude = body.location.coordinates[0];
      body.latitude = body.location.coordinates[1];
      delete body.location;
    }
    const stop = await Stop.create(body);
    res.status(201).json(stop);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { getStops, createStop };
