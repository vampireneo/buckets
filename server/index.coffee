dotenv = require 'dotenv'
dotenv.load()

_ = require 'underscore'
hbs = require 'hbs'
colors = require 'colors'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'
session = require 'cookie-session'
compression = require 'compression'
express = require 'express'
fs = require 'fs'

class Buckets
  constructor: (config) ->

    baseConfig = require './config'

    @config = baseConfig = _.extend baseConfig, config

    try
      newrelicConfig = require '../newrelic'
      if newrelicConfig.config.license_key
        newrelic = require 'newrelic'
        console.log 'Loaded newrelic'
        hbs.registerHelper 'newrelic', ->
          new hbs.handlebars.SafeString newrelic.getBrowserTimingHeader()
    catch e
      console.log 'Could not load newrelic', e

    passport = require './lib/auth'

    @routers =
      admin: require './routes/admin'
      api: require './routes/api'
      frontend: require './routes/frontend'

    @app = express()

    @app.use (req, res, next) ->
      req.startTime = Date.now()
      next()

    # Handle cookies and sessions and stuff
    @app.use compression()
    @app.use cookieParser @config.salt
    @app.use session
      secret: @config.salt
      name: 'buckets'
    @app.use bodyParser.json()
    @app.use bodyParser.urlencoded extended: true
    @app.use passport.initialize()
    @app.use passport.session()

    @app.set 'view engine', 'hbs'

    # Load Routes for the API, admin, and frontend
    @app.use "/#{@config.apiSegment}", @routers.api
    @app.use "/#{@config.adminSegment}", @routers.admin
    @app.use @routers.frontend

    @start() if @config.autoStart

  start: (done) ->
    done?() if @server
    @server ?= @app.listen @config.port, =>
      console.log ("\nBuckets is running at " + "http://localhost:#{@config.port}/".underline.bold).yellow
      done?()

  stop: (done) ->
    done?() unless @server
    @server.close done

# There can be only one #highlander
buckets = null
module.exports = (config={}) ->
  buckets ?= new Buckets config
