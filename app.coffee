{Scanner} = require('./scanner')
{User} = require('./models/user')

# set up express, socket.io, scanner
app = require('express')()
server = require('http').Server(app)
io = require('socket.io')(server)
scanner = new Scanner('192.168.1.1/24')

# configure express middleware
app.use(require('morgan')('dev'))
app.use(require('serve-static')("#{__dirname}/public"))
app.use(require('body-parser').urlencoded(extended: true))
app.set('view engine', 'jade')

# configure scanner to proxy results through to socket.io
scanner.on('results', ->
  io.emit('results', scanner.anonymousAddresses())
)

io.on('connection', (socket) ->
  socket.emit('results', scanner.anonymousAddresses())
)

# start scanner
scanner.scan()

# routes
app.get '/', (req, res) ->
  User.all (err, users) ->
    res.render('index', users: users)

app.get '/enrol', (req, res) ->
  res.render('enrol')

app.post '/enrol', (req, res) ->
  {name} = req.body
  ip     = req.ip
  
  return res.send('Sorry - your device is incompatible.', 500) unless ip of scanner.addresses
  
  mac = scanner.addresses[ip]
  
  User.create name, mac, ->
    res.redirect('/')

# listen on port 80
server.listen(8080)
