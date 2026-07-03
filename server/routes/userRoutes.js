const express = require("express");
const { getUsers } = require("../controllers/userController");
const { protect, authorize } = require("../middleware/auth");

const router = express.Router();

router.route("/")
  .get(protect, authorize("Super Admin"), getUsers);

module.exports = router;
