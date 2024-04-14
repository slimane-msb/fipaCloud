require('dotenv').config()

const express = require('express')
const app = express()
const bcrypt = require('bcrypt')
const passport = require('passport')
const flash = require('express-flash')
const session = require('express-session')
const methodOverride = require('method-override')
const mongoose = require('mongoose')
const User = require('./user')


// incude static files 
app.use(express.static('views'));

// auth
const initializePassport = require('./passport-config')
initializePassport(
  passport,
  async (email) => {
    const users = await User.find();
    return users.find(user => user.email === email);
  },
  async (id) => {
    const users = await User.find();
    return users.find(user => user._id === id);
  }
);


// end auth 

// database
uri = ''
if(process.env.PRODUCTION==="true"){
  const { DB_USER, DB_PASSWORD, DB_HOST, DB_PORT, DB_NAME } = process.env;

  uri = `mongodb://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?authSource=admin`;
  
}else{
  uri = process.env.DATABASE_URL;
}


console.log(uri)

function connectToMongoDB() {
  mongoose.connect(uri, { useNewUrlParser: true })
    .then(() => {
      console.log('[success] Connected to MongoDB');
    })
    .catch((error) => {
      console.log('[Error] Did not Connect to MongoDB');
      console.error('Error connecting to MongoDB:', error);
      setTimeout(connectToMongoDB, 5000); // try after 5sec (because docker compose build in parallel)
    });
}

connectToMongoDB();


app.use(express.json())

const usersRouter = require('./routes')

app.use('/users', usersRouter)

// end database bloc 

app.set('view-engine', 'ejs')
app.use(express.urlencoded({ extended: false }))
app.use(flash())
app.use(session({
  secret: process.env.SESSION_SECRET,
  resave: false,
  saveUninitialized: false
}))
app.use(passport.initialize())
app.use(passport.session())
app.use(methodOverride('_method'))

app.get('/', (req, res) => {
  res.render('index.ejs', { page_name_ejs: "index", name: whichUser(req) });
})


// static pages
app.get('/home', (req, res) => {
  res.render('index.ejs', { page_name_ejs: "index", name: whichUser(req) });
});

app.get('/services', (req, res) => {
  res.render('Services.ejs', { page_name_ejs: "Services", name: whichUser(req) })
})
app.get('/about', (req, res) => {
  res.render('About.ejs', { page_name_ejs: "About" , name: whichUser(req) })
})
app.get('/team', (req, res) => {
  res.render('Equipes.ejs', { page_name_ejs: "Equipes", name: whichUser(req)  })
})
app.get('/contact', (req, res) => {
  res.render('Contact.ejs', { page_name_ejs: "Contact", name: whichUser(req)  })
})

app.get('/mycloud', checkAuthenticated, (req, res) => {
  res.render('MyCloud.ejs', { page_name_ejs: "Services", name: whichUser(req)  })
})


// services pages
app.get('/vscode',checkAuthenticated, (req, res) => {
  if(process.env.PRODUCTION==="true"){
    console.log("ip_vscode (PRODUCTIN) = http://vscode-production:3000/")
    ip_vscode = "http://vscode-production:3000/"
  }else{
    console.log("ip_vscode (DEV) = http://vscode-dev:3000")
    ip_vscode = "http://vscode-dev:3000/"
  }
  res.redirect(ip_vscode)
})

app.get('/gitlab',checkAuthenticated, (req, res) => {
  if(process.env.PRODUCTION==="true"){
    console.log("ip_gitlab (PRODUCTIN) = http://gitlab-production:3000/")
    ip_gitlab = "http://gitlab-production:3000/"
  }else{
    console.log("ip_gitlab (DEV) = http://gitlab-dev:3000")
    ip_gitlab = "http://gitlab-dev:3000/"
  }
  res.redirect(ip_gitlab)
})


// login pages

app.get('/login', checkNotAuthenticated, (req, res) => {
  res.render('login.ejs', { page_name_ejs: "login" , name: whichUser(req) })
})

app.post('/login', checkNotAuthenticated, passport.authenticate('local', {
  successRedirect: '/',
  failureRedirect: '/login',
  failureFlash: true
}))

app.get('/register', checkNotAuthenticated, (req, res) => {
  res.render('register.ejs', { page_name_ejs: "register" , name: whichUser(req) })
})

app.post('/register', checkNotAuthenticated, async (req, res) => {
  try {
    const hashedPassword = await bcrypt.hash(req.body.password, 10)
    const user = new User({
      name: req.body.name,
      email: req.body.email,
      password: hashedPassword
    })
    const newUser = await user.save()
    res.redirect('/login')
  } catch {
    res.redirect('/register')
  }
})

app.delete('/logout', (req, res) => {
  req.logOut()
  res.redirect('/login')
})

function checkAuthenticated(req, res, next) {
  if (req.isAuthenticated()) {
    return next()
  }

  res.redirect('/login')
}

function checkNotAuthenticated(req, res, next) {
  if (req.isAuthenticated()) {
    return res.redirect('/')
  }
  next()
}

function whichUser(req) {
  if (req.isAuthenticated()) {
    return  req.user.name;
  } else {
    return "invite";
  }

}



console.log(`Listening on >>>> http://localhost:4000`);


app.listen(4000)