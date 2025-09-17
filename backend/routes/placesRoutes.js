const express = require('express');
const router = express.Router();
const placesController = require('../controllers/placesController');

router.get('/autocomplete', placesController.buscarCidades);

module.exports = router;
