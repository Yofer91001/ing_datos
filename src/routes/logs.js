const {Router} = require("express");

const router = Router();

router.get("/login", (req, res)=>{
    res.render("logs/login.hbs");
});

router.get("/logup", (req, res)=>{
    res.render("logs/logup.hbs");
});

module.exports = router;