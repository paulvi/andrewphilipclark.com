'use strict'

path = require 'path'
level = require 'level'

database = level('./s3-sync-cache')
db = -> database

module.exports = (grunt) ->
  @initConfig
    
    compass:
      options:
        basePath: './contents'
        sassDir: 'sass'
        cssDir: 'css'
        imagesDir: 'images'
        fontsDir: 'fonts'
        require: ['susy', 'breakpoint']
      preview:
        outputStyle: 'expanded'
      production:
        outputStyle: 'compressed'

    extend:
      options:
        deep: true
        defaults: grunt.file.readJSON 'config.json'
      staging:
        files:
          './config-staging.json': ['./config-staging-base.json']
      production:
        files:
          './config-production.json': ['./config-production-base.json']
      preview:
        files:
          './config-preview.json': ['./config-preview-base.json']

    wintersmith:
      staging:
        options:
          config: './config-staging.json'
      production:
        options:
          config: './config-production.json'
      preview:
        options:
          action: 'preview'
          config: './config-preview.json'

    watch:
      stylesheets:
        files: './contents/sass/**/*.scss'
        tasks: ['compass:preview']
        options:
          livereload: 1337

    concurrent:
      preview: ['watch', 'wintersmith:preview']

    clean:
      config: ['./config-staging.json', './config-production.json', './config-preview.json']
      staging: ['./public']

    aws: grunt.file.readJSON 'grunt-aws.json'
    's3-sync':
      options:
        key: '<%= aws.key %>'
        secret: '<%= aws.secret %>'
        bucket: '<%= aws.bucket %>'
        db: db
      deploy:
        files: [
          {
            root: path.join __dirname, 'deploy'
            src: ['deploy/**', '!deploy/images/**']
            dest: '/'
          },
          {
            root: path.join __dirname, 'deploy'
            src: 'deploy/images/**'
            dest: 'images/'
          }
        ]


  @loadNpmTasks "grunt-contrib-compass"
  @loadNpmTasks "grunt-contrib-watch"
  @loadNpmTasks "grunt-extend"
  @loadNpmTasks "grunt-wintersmith"
  @loadNpmTasks "grunt-concurrent"
  @loadNpmTasks "grunt-contrib-clean"
  @loadNpmTasks "grunt-s3-sync"

  @registerTask 'deploy', ['clean:staging', 'compass:production', 'extend:production', 'wintersmith:production', 'clean:config', 's3-sync:deploy']
  @registerTask 'stage', ['clean:staging', 'compass:production', 'extend:staging', 'wintersmith:staging', 'clean:config']
  @registerTask 'preview', ['extend:preview', 'compass:preview', 'concurrent:preview']
  
  @registerTask 'default', ['stage']