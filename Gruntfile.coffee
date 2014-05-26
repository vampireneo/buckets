config = require './server/config'
mongoose = require 'mongoose'

module.exports = (grunt) ->

  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'

    bower:
      install:
        options:
          targetDir: 'public/vendor/'
          layout: 'byComponent'
          cleanTargetDir: yes

    browserify:
      app:
        files:
          'public/js/buckets.js': ['client/source/**/*.{coffee,hbs}']
        options:
          transform: ['coffeeify', 'hbsfy']
          bundleOptions:
            debug: yes
          browserifyOptions:
            fullPaths: true
            basedir: "./client/source/"
            commondir: "./client/source/"
            extensions: ['.coffee', '.hbs']
            paths: ['./client/source', 'node_modules']
          alias: [
            './bower_components/backbone/backbone.js:backbone'
            './bower_components/jquery/dist/jquery.js:jquery'
            './bower_components/chaplin/chaplin.js:chaplin'
            './bower_components/underscore/underscore.js:underscore'
          ]
    concat:
      style:
        files:
          'public/css/buckets.css': [
            'public/fontastic/styles.css'
            'public/vendor/**/*.css'
            'public/css/bootstrap.css'
            'public/css/index.css'
          ]

    copy:
      assets:
        expand: yes
        cwd: 'client/assets'
        src: ['**/*']
        dest: 'public/'
      fontastic:
        expand: yes
        cwd: 'client/assets/fontastic/fonts/'
        src: ['*']
        dest: 'public/css/fonts/'

    cssmin:
      app:
        files:
          'public/css/buckets.css': [
            'public/css/buckets.css'
          ]

    express:
      dev:
        spawn: false
      server:
        options:
          background: false
      options:
        script: 'server/index.coffee'
        opts: ['node_modules/coffee-script/bin/coffee']


    less:
      app:
        expand: true,
        cwd: 'client/style'
        src: ['**/*.less']
        dest: 'public/css/'
        ext: '.css'

    modernizr:
      app:
        devFile: 'bower_components/modernizr/modernizr.js'
        outputFile: 'public/js/modernizr.min.js'
        files: 
          src: ['public/js/buckets.{css,js}']

    stylus:
      app:
        expand: yes
        cwd: 'client/style/'
        src: ['**/*.styl']
        dest: 'public/css/'
        ext: '.css'

    uglify:
      app:
        files:
          'public/js/buckets.js': ['public/js/buckets.js']

      vendor:
        dest: 'public/js/vendor.js'
        src: [
          'public/vendor/spin.js/spin.js'
          'public/vendor/ladda/js/ladda.js'
          'public/vendor/ladda/js/ladda.jquery.js'
          'public/vendor/**/*.js'
        ]
        filter: 'isFile'

      options:
        sourceMap: true

    watch:
      bower:
        files: ['bower.json']
        tasks: ['bower']

      clientjs:
        files: ['client/**/*.{coffee,hbs}']
        tasks: ['browserify:app']

      vendor:
        files: ['bower_components/**/*.{js,css}']
        tasks: ['bower', 'uglify:vendor', 'browserify:app']

      assets:
        files: ['client/assets/**/*.*']
        tasks: ['copy']

      style:
        files: ['client/style/**/*.{styl,less}']
        tasks: ['build-style']

      express:
        files: ['server/**/*.coffee']
        tasks: ['express:dev']
        options:
          spawn: false
          livereload: true

      livereload:
        options:
          livereload: true
        files: ['public/**/*']

  grunt.registerTask 'checkDatabase', (next, stuff...)->
    connection = mongoose.connect config.db, (err) ->
      if err
        throw "\nBuckets could not connect to MongoDB :/\n".magenta + "See the " + 'README.md'.bold + " for more info on installing MongoDB and check your settings at " + 'server/config.coffee'.bold + "."
        exit

  grunt.loadNpmTasks 'grunt-bower-task'
  grunt.loadNpmTasks 'grunt-browserify'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-contrib-concat'
  grunt.loadNpmTasks 'grunt-contrib-copy'
  grunt.loadNpmTasks 'grunt-contrib-cssmin'
  grunt.loadNpmTasks 'grunt-contrib-less'
  grunt.loadNpmTasks 'grunt-contrib-stylus'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-express-server'
  grunt.loadNpmTasks 'grunt-mocha'
  grunt.loadNpmTasks 'grunt-modernizr'

  grunt.registerTask 'build-style', ['stylus', 'less', 'concat:style']
  grunt.registerTask 'build-scripts', ['browserify:app']

  grunt.registerTask 'default', ['build']
  grunt.registerTask 'build', ['copy', 'bower', 'uglify:vendor', 'build-scripts', 'build-style', 'modernizr']
  grunt.registerTask 'minify', ['build', 'uglify:app', 'cssmin']

  grunt.registerTask 'dev', ['checkDatabase', 'express:dev', 'build', 'watch']
  grunt.registerTask 'devserve', ['checkDatabase', 'express:dev', 'watch']
  grunt.registerTask 'serve', ['checkDatabase', 'minify', 'express:server']