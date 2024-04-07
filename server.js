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
    console.log(users)
    return users.find(user => user.email === email);
  },
  async (id) => {
    users = await User.find();
    return users.find(user => user._id === id);
  }
);


// end auth 

// database
mongoose.connect(process.env.DATABASE_URL, { useNewUrlParser: true })

const db = mongoose.connection
db.on('error', (error) => console.error(error))
db.once('open', () => console.log('Connected to Database'))


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
  res.render('Services.ejs', { page_name_ejs: "Services", name: whichUser(req)  })
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

app.get('/mycloud', (req, res) => {
  res.render('MyCloud.ejs', { page_name_ejs: "Services", name: whichUser(req)  })
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
      id: Date.now().toString(),
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

app.listen(3000)