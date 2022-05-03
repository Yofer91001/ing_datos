const {Router} = require("express");
const { user } = require("pg/lib/defaults");

const router = Router();

router.get("/", (req, res)=>{

    const {user} = req.query;

    if(user != undefined){
       
        res.render("inicio.hbs", {user: user});
        
    }else{
        res.render("inicio.hbs");

    }
});

router.get("/inicio", (req, res)=>{

    const params = req.query;
    
    if(params.user != undefined){
        res.render("inicio.hbs", {user: params.user});
        
    }else{
        
        res.render("inicio.hbs");
    }
});

router.get("/consignaciones", (req, res)=>{
    const {user} = req.query;

    if(user != undefined){
        res.render("consignaciones.hbs", {user: user});
    }else{

        res.redirect("/inicio");

    }

});

router.get("/retiros", (req, res)=>{
    const {user} = req.query;

    if(user != undefined){
        res.render("retiros.hbs", {user: user});
    }else{

        res.redirect("/inicio");

    }

});

router.get("/conversiones", (req, res)=>{
    const {user} = req.query;

    if(user != undefined){
        res.render("conversiones.hbs", {user: user});
    }else{

        res.redirect("/inicio");
    }

});


router.get("/admin-panel", (req, res)=>{

    res.render("admin.hbs")

});

router.get("/*", (req, res)=>{
    res.render("error.hbs")

});

module.exports = router;