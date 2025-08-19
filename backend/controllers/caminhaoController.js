const CaminhaoModel = require('../models/caminhaoModel');

exports.criarCaminhao = async (req, res) => {
    try {
        const novo = await CaminhaoModel.inserirCaminhao(req.body);
        res.status(201).json(novo);
    } catch (error) {
        res.status(500).json({ error: 'Erro ao cadastrar caminhão: ' + error.message });    
    }
};