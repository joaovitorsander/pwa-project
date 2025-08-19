const express = require('express');
const router = express.Router();
const caminhaController = require('../controllers/caminhaoController');

router.post('/', caminhaController.criarCaminhao);

module.exports = router;