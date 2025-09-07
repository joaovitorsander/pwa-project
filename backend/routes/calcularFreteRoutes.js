const express = require('express');
const router = express.Router();
const freteController = require('../controllers/calcularFreteController');

router.post('/calcular', freteController.calcularFrete);
router.post('/', freteController.salvarFreteCalculado);

module.exports = router;