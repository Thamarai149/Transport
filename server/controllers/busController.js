const { Bus, Driver, Route } = require("../models/associations");

// @desc    Get all buses
// @route   GET /api/buses
// @access  Private
const getBuses = async (req, res) => {
  try {
    const buses = await Bus.findAll({
      include: [
        { model: Driver, as: "assignedDriver" },
        { model: Route, as: "currentRoute" },
      ],
    });
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
    const bus = await Bus.findByPk(req.params.id, {
      include: [
        { model: Driver, as: "assignedDriver" },
        { model: Route, as: "currentRoute" },
      ],
    });
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
    const bus = await Bus.create({
      busNumber,
      registrationNumber: registrationNumber || busNumber,
      capacity,
      ...rest,
    });
    res.status(201).json(bus);
  } catch (error) {
    res.status(400).json({ message: error.message });
  }
};

// @desc    Update a bus
// @route   PUT /api/buses/:id
// @access  Private/Admin
const updateBus = async (req, res) => {
  try {
    const [updated] = await Bus.update(req.body, {
      where: { id: req.params.id },
    });
    if (updated) {
      const bus = await Bus.findByPk(req.params.id);
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
    const deleted = await Bus.destroy({ where: { id: req.params.id } });
    if (deleted) {
      res.json({ message: "Bus removed" });
    } else {
      res.status(404).json({ message: "Bus not found" });
    }
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

module.exports = { getBuses, getBusById, createBus, updateBus, deleteBus };
