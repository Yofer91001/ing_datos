const {Router} = require("express");

const router = Router();

router.get("/", (req, res)=>{
    res.render("inicio.hbs");
});

router.get("/consignaciones", (req, res)=>{
    res.render("consignaciones.hbs")

});

router.get("/retiros", (req, res)=>{
    res.render("retiros.hbs")

});

router.get("/conversiones", (req, res)=>{
    res.render("conversiones.hbs")

});

router.get("/*", (req, res)=>{
    res.render("error.hbs")

});

module.exports = router;