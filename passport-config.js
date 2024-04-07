const LocalStrategy = require('passport-local').Strategy
const bcrypt = require('bcrypt')
const User = require('./user')

function initialize(passport,getUserByEmail, getUserById) {
  const authenticateUser = async (email, password, done) => {
    try{
        const user = await getUserByEmail(email)
        console.log(user)
        if (user == null) {
          return done(null, false, { message: 'No user with that email' })
        }
    } catch (e) {
      return done(e)
    }
    

    try {
      // on doit rajouter cette ligne a cause du await de JS 
      const user = await getUserByEmail(email)     
      if (await bcrypt.compare(password, user.password)) {
        
        return done(null, user)
      } else {
        return done(null, false, { message: 'Password incorrect' })
      }
    } catch (e) {
      return done(e)
    }
  }

  passport.use(new LocalStrategy({ usernameField: 'email' }, authenticateUser))
  passport.serializeUser((user, done) => done(null, user.id))
  passport.deserializeUser((id, done) => {
    return done(null, getUserById(id))
  })
}

module.exports = initialize