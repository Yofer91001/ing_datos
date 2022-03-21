const {Router} = require("express");
const { user } = require("pg/lib/defaults");

const router = Router();

router.get("/", (req, res)=>{

    const {user} = req.query;

    if(user.length > 0){
        res.render("inicio.hbs", {user: user});
    }
    
    res.render("inicio.hbs");
});

router.get("/inicio", (req, res)=>{

    const params = req.query;
    
    if(user.length > 0){
        res.render("inicio.hbs");
        
    }else{
        
        res.render("inicio.hbs", {user: params.user});
    }
});

router.get("/consignaciones", (req, res)=>{
    const {user} = req.query;

    if(user.length > 0){
        res.render("consignaciones.hbs", {user: user});
    }
    res.render("consignaciones.hbs")

});

router.get("/retiros", (req, res)=>{
    const {user} = req.query;

    if(user.length > 0){
        res.render("retiros.hbs", {user: user});
    }
    res.render("retiros.hbs")

});

router.get("/conversiones", (req, res)=>{
    const {user} = req.query;

    if(user.length > 0){
        res.render("conversiones.hbs", {user: user});
    }
    res.render("conversiones.hbs")

});

router.get("/*", (req, res)=>{
    res.render("error.hbs")

});

module.exports = router;