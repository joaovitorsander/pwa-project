const express = require('express');
const cors = require('cors');
const caminhaoRoutes = require('./routes/caminhaoRoutes');

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.use('/caminhoes', caminhaoRoutes);

app.get('/', (req, res) => {
    res.send('Api funcionando')
});

app.listen(port, () => {
    console.log(`Servidor rodando na porta ${port}`);
});