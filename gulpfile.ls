/**
 * @version r7
 * @author Viacheslav Lotsmanov
 * @license GNU/GPLv3 (https://github.com/unclechu/web-front-end-gulp-template/blob/master/LICENSE)
 * @see {@link https://github.com/unclechu/web-front-end-gulp-template|GitHub}
 */

require! {
	path

	gulp
	yargs : {argv}
	\merge-stream : merge

	del
	\gulp.spritesmith : spritesmith
	\gulp-task-listing : tasks
	\gulp-less : less
	\gulp-stylus : stylus
	\gulp-if : gulpif
	\gulp-rename : rename
	\gulp-browserify : browserify
	liveify
	\gulp-uglify : uglify
	\gulp-jshint : jshint
	\jshint-stylish : stylish
}

pkg = require path.join process.cwd() , './package.json'

gulp.task \help , tasks

production = argv.production?

# helpers {{{1

rename-build-file = (build-path, main-src, build-file) !->
	if build-path.basename is path.basename main-src, path.extname main-src
		build-path.extname = path.extname build-file
		build-path.basename = path.basename build-file, build-path.extname

init-task-iteration = (name, item, init-func) !->
	init-func name, item
	if item.sub-tasks then for sub-task-name, sub-task of item.sub-tasks
		sub-task-params = ^^item
		sub-task-params.sub-task = null
		for key, val of sub-task then sub-task-params[key] = val
		init-func name + \- + sub-task-name, sub-task-params, true

# helpers }}}1

# clean {{{1

clean-data = pkg.gulp.clean or []
dist-clean-data = pkg.gulp.distclean or []

gulp.task \clean , [
	\clean-sprites
	\clean-styles
	\clean-scripts
], (cb) !-> del clean-data , cb

gulp.task \distclean , [ \clean ], (cb) !-> del dist-clean-data , cb

# clean }}}1

# sprites {{{1

sprites-clean-tasks = []
sprites-build-tasks = []

sprites-data = pkg.gulp.sprites or {}

sprite-clean-task = (name, sprite-params, params, cb) !->
	del [
		path.join params.img-dir, 'build/'
		path.join params.css-dir, sprite-params.css-name
	], cb

sprite-build-task = (name, sprite-params, params) ->
	sprite-data = gulp.src path.join params.img-dir, 'src/*.png'
		.pipe spritesmith sprite-params
	img = sprite-data.img.pipe gulp.dest path.join params.img-dir, 'build/'
	css = sprite-data.css.pipe gulp.dest params.css-dir
	[ img, css ]

sprite-init-tasks = (name, item, sub-task=false) !->
	img-name = item.img-name or \sprite.png
	sprite-params =
		img-name: img-name
		css-name: item.css-name or name + '.css'
		img-path: path.join item.img-path-prefix, 'build/', img-name
		padding: item.padding or 1
		img-opts: format: \png
		css-var-map: let name then (s) !->
			s.name = \sprite- + name + \- + s.name;
		algorithm: item.algorithm or \top-down

	params =
		img-dir: item.img-dir
		css-dir: item.css-dir

	pre-build-tasks = [\clean-sprite- + name]

	if item.build-deps then
		for task-name in item.build-deps
			pre-build-tasks.push task-name

	gulp.task \clean-sprite- + name,
		let name, sprite-params, params
			(cb) !-> sprite-clean-task name, sprite-params, params, cb

	gulp.task \sprite- + name, pre-build-tasks,
		let name, sprite-params, params
			-> merge.apply null, sprite-build-task name, sprite-params, params

	sprites-clean-tasks.push \clean-sprite- + name
	if not sub-task then sprites-build-tasks.push \sprite- + name

for name, item of sprites-data
	init-task-iteration name, item, sprite-init-tasks

gulp.task \clean-sprites , sprites-clean-tasks
gulp.task \sprites , sprites-build-tasks

# sprites }}}1

# styles {{{1

styles-clean-tasks = []
styles-build-tasks = []

styles-data = pkg.gulp.styles or {}

styles-clean-task = (name, params, cb) !->
	del path.join( params.path, 'build/' ) , cb

styles-build-task = (name, params) ->
	gulp.src path.join params.path, 'src/', params.main-src
		.pipe gulpif params.type is \less , less compress: production
		.pipe gulpif params.type is \stylus , stylus compress: production
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest path.join params.path, 'build/'

styles-init-tasks = (name, item, sub-task=false) !->
	params =
		type: item.type
		path: item.path
		main-src: item.main-src
		build-file: item.build-file

	pre-build-tasks = [\clean-styles- + name]

	if item.build-deps then
		for task-name in item.build-deps
			pre-build-tasks.push task-name

	gulp.task \clean-styles- + name,
		let name, params then (cb) !-> styles-clean-task name, params, cb

	if item.type is \less or item.type is \stylus
		gulp.task \styles- + name, pre-build-tasks,
			let name, params then -> styles-build-task name, params
	else
		throw new Error "Unknown styles type for \"#name\" task."

	styles-clean-tasks.push \clean-styles- + name
	if not sub-task then styles-build-tasks.push \styles- + name

for name, item of styles-data
	init-task-iteration name, item, styles-init-tasks

gulp.task \clean-styles , styles-clean-tasks
gulp.task \styles , styles-build-tasks

# styles }}}1

# scripts {{{1

scripts-clean-tasks = []
scripts-build-tasks = []

scripts-data = pkg.gulp.scripts or {}

scripts-clean-task = (name, params, cb) !->
	del path.join( params.path, 'build/' ) , cb

scripts-jshint-task = (name, params) ->
	src = [ path.join params.path, 'src/**/*.js' ]
	for exclude in params.jshint-exclude then src.push \! + exclude
	gulp.src src .pipe jshint params.jshint-params
		.pipe jshint.reporter stylish

scripts-build-browserify-task = (name, params) ->
	options =
		shim: params.shim
		debug: not production

	if params.type is \liveify
		options.transform = [ \liveify ]
		options.extensions = [ \.ls ]

	gulp.src path.join( params.path, 'src/', params.main-src ), read: false
		.pipe browserify options
		.pipe gulpif production, uglify preserveComments: \some
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest path.join params.path, 'build/'

scripts-init-tasks = (name, item, sub-task=false) !->
	# parse relative paths in "shim"
	if item.shim then for key, shim-item of item.shim
		for param-name, val of shim-item
			if param-name is \relativePath
				shim-item.path = path.join item.path, 'src/', val
				delete shim-item[param-name]

	params =
		type: item.type
		path: item.path
		main-src: item.main-src
		build-file: item.build-file
		shim: item.shim or {}
		jshint-disabled: item.jshint-disabled and true or false
		jshint-params: item.jshint-params and item.jshint-params or null
		jshint-exclude: item.jshint-exclude and item.jshint-exclude or []

	if item.type is \liveify
		params.jshint-exclude.push path.join item.path, 'src/**/*.ls'

	if item.jshint-relative-exclude
		for exclude in item.jshint-relative-exclude
			params.jshint-exclude.push path.join item.path, 'src/', exclude

	pre-build-tasks = [\clean-scripts- + name]

	if item.build-deps then
		for task-name in item.build-deps
			pre-build-tasks.push task-name

	if not params.jshint-disabled
		gulp.task \scripts- + name + \-jshint,
			let name, params then -> scripts-jshint-task name, params
		pre-build-tasks.push \scripts- + name + \-jshint

	gulp.task \clean-scripts- + name,
		let name, params then (cb) !-> scripts-clean-task name, params, cb

	if item.type is \browserify or item.type is \liveify
		gulp.task \scripts- + name, pre-build-tasks,
			let name, params then -> scripts-build-browserify-task name, params
	else
		throw new Error "Unknown scripts type for \"#name\" task."

	scripts-clean-tasks.push \clean-scripts- + name
	if not sub-task then scripts-build-tasks.push \scripts- + name

for name, item of scripts-data
	init-task-iteration name, item, scripts-init-tasks

gulp.task \clean-scripts , scripts-clean-tasks
gulp.task \scripts , scripts-build-tasks

# scripts }}}1

gulp.task \default [
	\sprites
	\styles
	\scripts
]
