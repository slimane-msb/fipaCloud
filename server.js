if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config()
}

const express = require('express')
const app = express()
const bcrypt = require('bcrypt')
const passport = require('passport')
const flash = require('express-flash')
const session = require('express-session')
const methodOverride = require('method-override')


// incude static files 
app.use(express.static('views'));

const initializePassport = require('./passport-config')
initializePassport(
  passport,
  email => users.find(user => user.email === email),
  id => users.find(user => user.id === id)
)

const users = []

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
  // res.render('index.ejs', { name: req.user.name })
  let user_name;

  if (req.isAuthenticated()) {
    user_name = req.user.name;
  } else {
    user_name = "invite";
  }

  res.render('index.ejs', { page_name_ejs: "index", name: user_name });
})


// static pages
app.get('/home', (req, res) => {
  let user_name;

  if (req.isAuthenticated()) {
    user_name = req.user.name;
  } else {
    user_name = "invite";
  }

  res.render('index.ejs', { page_name_ejs: "index", name: user_name });
});

app.get('/services', (req, res) => {
  res.render('Services.ejs', { page_name_ejs: "Services", name: req.user.name })
})
app.get('/about', (req, res) => {
  res.render('About.ejs', { page_name_ejs: "About" , name: req.user.name})
})
app.get('/team', (req, res) => {
  res.render('Equipes.ejs', { page_name_ejs: "Equipes", name: req.user.name })
})
app.get('/contact', (req, res) => {
  res.render('Contact.ejs', { page_name_ejs: "Contact", name: req.user.name })
})

app.get('/mycloud', (req, res) => {
  res.render('MyCloud.ejs', { page_name_ejs: "Services", name: req.user.name })
})


// login pages

app.get('/login', checkNotAuthenticated, (req, res) => {
  res.render('login.ejs', { page_name_ejs: "login" })
})

app.post('/login', checkNotAuthenticated, passport.authenticate('local', {
  successRedirect: '/',
  failureRedirect: '/login',
  failureFlash: true
}))

app.get('/register', checkNotAuthenticated, (req, res) => {
  res.render('register.ejs')
})

app.post('/register', checkNotAuthenticated, async (req, res) => {
  try {
    const hashedPassword = await bcrypt.hash(req.body.password, 10)
    users.push({
      id: Date.now().toString(),
      name: req.body.name,
      email: req.body.email,
      password: hashedPassword
    })
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

app.listen(3000)