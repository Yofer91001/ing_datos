const express = require("express");
const body_parser = require("Body-parser");
const morgan = require ("Morgan");
const exphbs = require("express-handlebars");
const path = require("path");

const app = express();

//Middlewares


//Requerimientos y declaraciones
app.use(express.static("public"));
app.use(require("./routes/logs.js"));
app.use(require("./routes/app.js"));

app.set("views", path.join(__dirname + "/views"))
app.engine(".hbs", exphbs.engine({
    defaultLayout: "main",
    layoutDir: path.join(app.get("views"), "/layouts"),
    partialsDir: path.join(app.get("views"), "/partials"),
	extname: ".hbs"

}));
app.set("view engine", ".hbs");



app.listen(8080);