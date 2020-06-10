path = require 'path'

cdnJs = [
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular.min.js'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-animate.min.js'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-aria.min.js'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-messages.min.js'
	'https://cdnjs.cloudflare.com/ajax/libs/angular-ui-router/0.2.18/angular-ui-router.min.js'
	'https://ajax.googleapis.com/ajax/libs/angular_material/1.0.9/angular-material.min.js'
	'https://cdnjs.cloudflare.com/ajax/libs/angular-material-icons/0.7.0/angular-material-icons.min.js'
	'https://cdnjs.cloudflare.com/ajax/libs/ngStorage/0.3.6/ngStorage.min.js'
	'https://d3js.org/d3.v3.min.js'
	'https://cdnjs.cloudflare.com/ajax/libs/json3/3.3.2/json3.min.js'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-mocks.js'
]

cdnCss = [
	'https://ajax.googleapis.com/ajax/libs/angular_material/1.0.9/angular-material.min.css'
]

mapFiles = [
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-messages.min.js.map'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-aria.min.js.map'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular.min.js.map'
	'https://ajax.googleapis.com/ajax/libs/angularjs/1.5.8/angular-animate.min.js.map'
]

# Build configurations
module.exports = (grunt) ->
	require('load-grunt-tasks')(grunt)
	require('time-grunt')(grunt)
	pkg = require './package.json'

	grunt.initConfig
		settings:
			distDirectory: 'dist'
			srcDirectory: 'src'
			tempDirectory: '.temp'

		# Deletes dist and .temp directories
		# The .temp directory is used during the build process
		# The dist directory contains the artifacts of the build
		# These directories should be deleted before subsequent builds
		# These directories are not committed to source control
		clean:
			working: [
				'<%= settings.tempDirectory %>'
				'<%= settings.distDirectory %>'
			]
			js: [
				'<%= settings.tempDirectory %>/scripts/**/*.js'
				'<%= settings.tempDirectory %>/scripts/**/*.map'
				'<%= settings.tempDirectory %>/scripts/**/*.coffee'
				'!<%= settings.tempDirectory %>/scripts/**/*.min.js'
				'!<%= settings.tempDirectory %>/scripts/scripts.js.map'
			]

		# Compiles CoffeeScript (.coffee) files to JavaScript (.js)
		coffee:
			app:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: '**/*.coffee'
					dest: '<%= settings.tempDirectory %>'
					expand: true
					ext: '.js'
				]
				options:
					sourceMap: false

		# Lints CoffeeScript files
		coffeelint:
			app:
				files: [
					cwd: ''
					src: [
						'src/**/*.coffee'
						'!src/scripts/libs/**'
					]
				]
				options:
					indentation:
						value: 1
					max_line_length:
						level: 'ignore'
					no_tabs:
						level: 'ignore'

		# Sets up a web server
		connect:
			app:
				options:
					base: '<%= settings.distDirectory %>'
					hostname: '0.0.0.0' # make server accessible via the network
					livereload: true
					middleware: (connect, options, middlewares) ->

						# enable Angular's HTML5 mode
						modRewrite = require 'connect-modrewrite'
						middlewares.unshift(modRewrite(['!\\.html|\\.js|\\.svg|\\.css|\\.appcache|\\.png$ /index.html [L]']));
						return middlewares;

					open: true
					port: 0

		# Copies directories and files from one location to another
		copy:
			app:
				files: [
					cwd: '<%= settings.srcDirectory %>'
					src: '**'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				,
					cwd: '.components/'
					src: '**'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				]
			dev:
				cwd: '<%= settings.tempDirectory %>'
				src: '**'
				dest: '<%= settings.distDirectory %>'
				expand: true
			prod:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: [
						'**/*.{gif,jpeg,jpg,png,webp}'
						'**/*.{css,js,html,map,config,appcache}'
						]
					dest: '<%= settings.distDirectory %>'
					expand: true
				]

		# Compresses image files
		imagemin:
			images:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: '**/*.{gif,jpeg,jpg}'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				]
				options:
					optimizationLevel: 7

		# Runs unit tests using karma
		karma:
			unit:
				options:
					browsers: [
						'Firefox'
					]
					captureTimeout: 5000
					colors: true
					files: cdnJs.concat([
						'dist/**/main.js'
						'dist/**/*.js'
						'test/**/*.{coffee,js}'
					])
					frameworks: [
						'jasmine'
					]
					junitReporter:
						outputFile: 'test-results.xml'
					keepalive: false
					logLevel: 'INFO'
					port: 9876
					preprocessors:
						'**/*.coffee': 'coffee'
					reporters: [
						'spec'
					]
					runnerPort: 9100
					singleRun: true

		# Compile LESS (.less) files to CSS (.css)
		less:
			app:
				files:
					'.temp/styles/styles.css': '.temp/styles/**.less'

		# Convert CoffeeScript classes to AngularJS modules
		ngClassify:
			app:
				files: [
					cwd: '<%= settings.tempDirectory %>'
					src: '**/*.coffee'
					dest: '<%= settings.tempDirectory %>'
					expand: true
				]

		cacheBust:
			taskName:
				options:
					assets: [
						'.temp/scripts/**/*.js'
						'.temp/styles/styles.css'
					]
					deleteOriginals: true
				src: []

		includeSource:
			options:
				basePath: '.temp'
			myTarget:
				files:
					'.temp/index.html': '.temp/index.html'

		template:
			dev:
				files: '.temp/index.html': '.temp/index.html'
				cdnJs: cdnJs
				cdnCss: cdnCss
			prod:
				files: '.temp/index.html': '.temp/index.html'
				environment: 'prod'
				cdnJs: cdnJs
				cdnCss: cdnCss

		ngtemplates:
			app:
				cwd: '.temp',
				src: 'views/**/*.html',
				dest: '.temp/scripts/templates.js'
				options:
					htmlmin:
						collapseBooleanAttributes:      true
						collapseWhitespace:             true
						removeAttributeQuotes:          true
						removeComments:                 true
						removeEmptyAttributes:          true
						removeRedundantAttributes:      true
						removeScriptTypeAttributes:     true
						removeStyleLinkTypeAttributes:  true

		uglify:
			options:
				mangle: false
			my_target:
				files:
					'.temp/scripts/scripts.min.js': '.temp/scripts/scripts.js'

		concat:
			options:
				separator: ';'
				sourceMap: true
			dist:
				src: ['.temp/scripts/*.js', '.temp/scripts/**/*.js']
				dest: '.temp/scripts/scripts.js'

		appcache:
			options:
				basePath: '.temp/'
			all:
				dest: '.temp/manifest.appcache'
				cache:
					patterns: [
						'.temp/**/*'
						'!.temp/web.config'
					]
				network: [
					'https://angular-apt.azurewebsites.net/api/*'
				].concat(cdnJs).concat(cdnCss).concat(mapFiles)

		# Run tasks when monitored files change
		watch:
			basic:
				files: [
					'src/fonts/**'
					'src/images/**'
					'src/scripts/**/*.js'
					'src/styles/**/*.css'
					'src/**/*.html'
					'src/resources/*'
				]
				tasks: [
					'copy:app'
					'less'
					'includeSource'
					'template:dev'
					'copy:dev'
				]
				options:
					livereload: true
					nospawn: true
			coffee:
				files: 'src/scripts/**/*.coffee'
				tasks: [
					'clean:working'
					'coffeelint'
					'copy:app'
					'ngClassify:app'
					'coffee:app'
					'less'
					'includeSource'
					'template:dev'
					'copy:dev'
					#'karma'
				]
				options:
					livereload: true
					nospawn: true
			less:
				files: 'src/styles/**/*.less'
				tasks: [
					'copy:app'
					'less'
					'template:dev'
					'includeSource'
					'copy:dev'
				]
				options:
					livereload: true
					nospawn: true
			test:
				files: 'test/**/*.*'
				tasks: [
					'karma'
				]
			# Used to keep the web server alive
			none:
				files: 'none'
				options:
					livereload: true


	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Enter the following command at the command line to execute this build task:
	# grunt build
	grunt.registerTask 'build', [
		'clean:working'
		'coffeelint'
		'copy:app'
		'ngClassify'
		'coffee:app'
		'less'
		'includeSource'
		'template:dev'
		'copy:dev'
	]

	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Opens the app in the default browser
	# Watches for file changes, and compiles and reloads the web browser upon change
	# Enter the following command at the command line to execute this build task:
	# grunt or grunt default
	grunt.registerTask 'default', [
		'build'
		'connect'
		'watch'
	]

	# Identical to the default build task
	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Opens the app in the default browser
	# Watches for file changes, and compiles and reloads the web browser upon change
	# Enter the following command at the command line to execute this build task:
	# grunt dev
	grunt.registerTask 'dev', [
		'default'
	]

	# Compiles the app with optimized build settings
	# Places the build artifacts in the dist directory
	# Enter the following command at the command line to execute this build task:
	# grunt prod
	grunt.registerTask 'prod', [
		'clean:working'
		'coffeelint'
		'copy:app'
		'ngClassify'
		'coffee:app'
		'imagemin'
		'less'
		'ngtemplates'
		'concat'
		'uglify'
		'clean:js'
		'cacheBust'
		'template:prod'
		'includeSource'
		'appcache'
		'copy:prod'
	]

	# Opens the app in the default browser
	# Build artifacts must be in the dist directory via a prior grunt build, grunt, grunt dev, or grunt prod
	# Enter the following command at the command line to execute this build task:
	# grunt server
	grunt.registerTask 'server', [
		'connect'
		'watch:none'
	]

	# Looks like the prevailing winds are pointing to use 'serve' instead of 'server'
	# Why not both?  :)
	# grunt serve
	grunt.registerTask 'serve', [
		'server'
	]

	# Compiles the app with non-optimized build settings
	# Places the build artifacts in the dist directory
	# Runs unit tests via karma
	# Enter the following command at the command line to execute this build task:
	# grunt test
	grunt.registerTask 'test', [
		'build'
		'karma'
	]
