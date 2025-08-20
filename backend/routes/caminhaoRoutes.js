const express = require('express');
const router = express.Router();
const caminhaoController = require('../controllers/caminhaoController');

router.post('/', caminhaoController.criarCaminhao);

module.exports = router;