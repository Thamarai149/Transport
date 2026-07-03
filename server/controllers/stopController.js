const Stop = require("../models/Stop");

// @desc    Get all stops
// @route   GET /api/stops
// @access  Private
const getStops = async (req, res) => {
  try {
    const stops = await Stop.find();
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
    const stop = new Stop(req.body);
    const createdStop = await stop.save();
    res.status(201).json(createdStop);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { getStops, createStop };
