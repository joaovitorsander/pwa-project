const express = require("express");
const cors = require("cors");
const caminhaoRoutes = require("./routes/caminhaoRoutes");
const tiposcargaRoutes = require("./routes/tiposcargaRoutes");
const calcularFreteRoutes = require("./routes/calcularFreteRoutes");

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.use("/caminhoes", caminhaoRoutes);
app.use("/tiposcarga", tiposcargaRoutes);
app.use("/fretes", calcularFreteRoutes);

app.get("/", (req, res) => {
  res.send("Api funcionando");
});

app.listen(port, () => {
  console.log(`Servidor rodando na porta ${port}`);
});
