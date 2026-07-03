const axios = require("axios");

const AI_SERVICE_URL = process.env.AI_SERVICE_URL || "http://localhost:8000";

// @desc    Match a student's live face encoding against registered profiles
// @route   POST /api/ai/face-match
// @access  Private
const matchFace = async (req, res) => {
  try {
    const response = await axios.post(`${AI_SERVICE_URL}/ai/face-match`, req.body);
    res.json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({ message: "AI service is unavailable. Is the Python server running?" });
    }
  }
};

// @desc    Optimize the order of bus stops for a route
// @route   POST /api/ai/optimize-route
// @access  Private/Admin
const optimizeRoute = async (req, res) => {
  try {
    const response = await axios.post(`${AI_SERVICE_URL}/ai/optimize-route`, req.body);
    res.json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({ message: "AI service is unavailable. Is the Python server running?" });
    }
  }
};

// @desc    Predict ETA for a bus to reach its next stop
// @route   POST /api/ai/predict-eta
// @access  Private
const predictETA = async (req, res) => {
  try {
    const response = await axios.post(`${AI_SERVICE_URL}/ai/predict-eta`, req.body);
    res.json(response.data);
  } catch (error) {
    if (error.response) {
      res.status(error.response.status).json(error.response.data);
    } else {
      res.status(503).json({ message: "AI service is unavailable. Is the Python server running?" });
    }
  }
};

module.exports = { matchFace, optimizeRoute, predictETA };
