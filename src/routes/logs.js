const {Router} = require("express");
const res = require("express/lib/response");
const { redirect, render } = require("express/lib/response");
const {Pool} = require("pg");
const { client_encoding } = require("pg/lib/defaults");






//ENRUTADOR
const router = Router();

//INICIO DE LA CONEXIÓN
const pool = new Pool({
    host: "localhost",
    user: "postgres",
    database: "exval",
    password: "admin123",
    port: 5432
});


router.get("/login", (req, res)=>{
    
    res.render("logs/login.hbs");
});



router.post("/login", async (req, res)=>{

    
    const {email, password} = req.body

    if(email.length > 0 ){
        

        pool.connect();
    
    
        const query = await pool.query("SELECT pass, user_name FROM users WHERE email = $1", [email]);
        const query2 = await pool.query("SELECT pass, user_name FROM users WHERE user_name = $1", [email]);

        
        
        if(query.rows[0] != undefined ){
            if(query.rows[0].pass == password)
                res.redirect("/inicio/?user=" + query.rows[0].user_name);
                
            
            
        }else if(query2.rows[0] != undefined){
            console.log(query2.rows[0].pass);
            if(query2.rows[0].pass == password)
                res.redirect("/inicio/?user=" + email);
           
        }
        
        await pool.end();
        
    }
    res.render("logs/login.hbs")

    
    

    
});

router.get("/logup", (req, res)=>{
    res.render("logs/logup.hbs");
});

router.post("/logup", async (req, res)=>{

    const {email, pass, user, name} = req.body

    
    
    if(email.length > 0 && pass.length > 0 && name.length > 0 && user.length > 0){
        
        pool.connect();
        
        
        const query = await pool.query("SELECT email FROM users WHERE email = $1", [email]);
        const query2 = await pool.query("SELECT user FROM users WHERE user_name = $1", [user]);


        
        
        if(query.rows[0] != undefined || query2.rows[0] != undefined){
            res.redirect("/login")
        }else{
            await pool.query("INSERT INTO users(user_name  , name, email, pass) VALUES  ($1,$2,$3,$4)", [user, name, email, pass]);
            
            res.redirect("/inicio/?user=" +  user);
        } 
        await pool.end();
    }else{
        res.render("/logup")
    }
    
    
});

router.get("/logout", (req, res)=>{
    res.redirect("/inicio")
});

module.exports = router;