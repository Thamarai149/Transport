const Route = require("../models/Route");

// @desc    Get all routes
// @route   GET /api/routes
// @access  Private
const getRoutes = async (req, res) => {
  try {
    const routes = await Route.find().populate("stops");
    res.json(routes);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create new route
// @route   POST /api/routes
// @access  Private/Admin
const createRoute = async (req, res) => {
  try {
    const {
      routeName,
      routeNumber,
      startPoint,
      endPoint,
      college,
      name,
      startLocation,
      endLocation,
    } = req.body;

    const route = new Route({
      routeName: routeName || name,
      routeNumber: routeNumber || name || `R-${Date.now()}`,
      startPoint: startPoint || startLocation,
      endPoint: endPoint || endLocation,
      college: college || "Default College",
    });
    const createdRoute = await route.save();
    res.status(201).json(createdRoute);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

module.exports = { getRoutes, createRoute };
