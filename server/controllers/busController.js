const Bus = require("../models/Bus");

// @desc    Get all buses
// @route   GET /api/buses
// @access  Private
const getBuses = async (req, res) => {
  try {
    const buses = await Bus.find().populate("assignedDriver").populate("currentRoute");
    res.json(buses);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Get bus by ID
// @route   GET /api/buses/:id
// @access  Private
const getBusById = async (req, res) => {
  try {
    const bus = await Bus.findById(req.params.id).populate("assignedDriver").populate("currentRoute");
    if (bus) {
      res.json(bus);
    } else {
      res.status(404).json({ message: "Bus not found" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// @desc    Create new bus
// @route   POST /api/buses
// @access  Private/Admin
const createBus = async (req, res) => {
  try {
    const { busNumber, registrationNumber, capacity, ...rest } = req.body;
    const bus = new Bus({
      busNumber,
      registrationNumber: registrationNumber || busNumber,
      capacity,
      ...rest,
    });
    const createdBus = await bus.save();
    res.status(201).json(createdBus);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Update a bus
// @route   PUT /api/buses/:id
// @access  Private/Admin
const updateBus = async (req, res) => {
  try {
    const bus = await Bus.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (bus) {
      res.json(bus);
    } else {
      res.status(404).json({ message: "Bus not found" });
    }
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Delete a bus
// @route   DELETE /api/buses/:id
// @access  Private/Admin
const deleteBus = async (req, res) => {
  try {
    const bus = await Bus.findByIdAndDelete(req.params.id);
    if (bus) {
      res.json({ message: "Bus removed" });
    } else {
      res.status(404).json({ message: "Bus not found" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getBuses, getBusById, createBus, updateBus, deleteBus };
