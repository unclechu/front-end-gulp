/**
 * @version r2
 * @author Viacheslav Lotsmanov
 * @license GNU/GPLv3 by Free Software Foundation (https://github.com/unclechu/web-front-end-gulp-template/blob/master/LICENSE)
 * @see {@link https://github.com/unclechu/web-front-end-gulp-template|GitHub}
 */

require! {
	pkg: './package.json'

	path

	gulp
	argv: yargs .argv
	merge: \merge-stream

	clean: \gulp-clean
	spritesmith: \gulp.spritesmith
	tasks: \gulp-task-listing
	less: \gulp-less
	gulpif: \gulp-if
	rename: \gulp-rename
	browserify: \gulp-browserify
	uglify: \gulp-uglify
	jshint: \gulp-jshint
	stylish: \jshint-stylish
}

gulp.task \help, tasks

production = argv.production?

# helpers {{{1

rename-build-file = (build-path, main-src, build-file) !->
	if build-path.basename is path.basename main-src, path.extname main-src
		build-path.extname = path.extname build-file
		build-path.basename = path.basename build-file, build-path.extname

# helpers }}}1

# clean {{{1

clean-data = pkg.gulp.clean or []
dist-clean-data = pkg.gulp.distclean or []

clean-task = (list) ->
	return [gulp] if not Array.isArray list
	retval = []
	for item in list
		retval.push(gulp.src item .pipe clean force: true)
	retval

gulp.task \clean, [
	\clean-sprites
	\clean-less
	\clean-browserify
], ->
	merge.apply null, clean-task clean-data

gulp.task \distclean, [\clean], ->
	merge.apply null, clean-task dist-clean-data

# clean }}}1

# sprites {{{1

sprites-clean-tasks = []
sprites-build-tasks = []

sprites-data = pkg.gulp.sprites or {}

sprite-clean-task = (name, sprite-params, params) ->
	gulp.src [
		path.join params.img-dir, 'build/'
		path.join params.css-dir, sprite-params.css-name
	] .pipe clean force: true

sprite-build-task = (name, sprite-params, params) ->
	sprite-data = gulp.src path.join params.img-dir, 'src/*.png'
	img = sprite-data.img.pipe gulp.dest path.join params.img-dir, 'build/'
	css = sprite-data.css.pipe gulp.dest params.css-dir
	[ img, css ]

for name, item of sprites-data
	img-name = item.img-name or \sprite.png
	sprite-params =
		img-name: img-name
		css-name: item.css-name or name + '.css'
		img-path: path.join item.img-path-prefix, 'build/', img-name
		padding: item.padding or 1
		img-opts: format: \png
		css-var-map: (s) !->
			s.name = \sprite- + name + \- + s.name;
		algorithm: item.algorithm or \top-down

	params =
		img-dir: item.img-dir
		css-dir: item.css-dir

	gulp.task \clean-sprite- + name, ->
		merge.apply null, sprite-clean-task name, sprite-params, params

	gulp.task \sprite- + name, [\clean-sprite- + name], ->
		merge.apply null, sprite-build-task name, sprite-params, params

	sprites-clean-tasks.push \clean-sprite- + name
	sprites-build-tasks.push \sprite- + name

gulp.task \clean-sprites, sprites-clean-tasks
gulp.task \sprites, sprites-build-tasks

# sprites }}}1

# less {{{1

less-clean-tasks = []
less-build-tasks = []

less-data = pkg.gulp.less or {}

less-clean-task = (name, params) ->
	gulp.src path.join params.path, 'build/' .pipe clean force: true

less-build-task = (name, params) ->
	gulp.src path.join params.path, 'src/', params.main-src
		.pipe less compress: production
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest path.join params.path, 'build/'

for name, item of less-data
	params =
		path: item.path
		main-src: item.main-src
		build-file: item.build-file

	required-sprites = []
	if item.required-sprites then
		for sprite-name in item.required-sprites
			required-sprites.push \sprite- + sprite-name

	gulp.task \clean-less- + name, required-sprites, ->
		less-clean-task name, params

	gulp.task \less- + name, [\clean-less- + name], ->
		less-build-task name, params

	less-clean-tasks.push \clean-less- + name
	less-build-tasks.push \less- + name

gulp.task \clean-less, less-clean-tasks
gulp.task \less, less-build-tasks

# less }}}1

# browserify {{{1

browserify-clean-tasks = []
browserify-build-tasks = []

browserify-data = pkg.gulp.browserify or {}

browserify-clean-task = (name, params) ->
	gulp.src path.join params.path, 'build/' .pipe clean force: true

browserify-jshint-task = (name, params) ->
	src = [ path.join params.path, 'src/**/*.js' ]
	for item in params.jshint-exclude then src.push \! + exclude
	gulp.src src .pipe jshint params.jshint-params
		.pipe jshint.reporter stylish

browserify-build-task = (name, params) ->
	gulp.src path.join params.path, 'src/', params.main-src
		.pipe browserify shim: params.shim, debug: not production
		.pipe gulpif production, uglify preserveComments: \some
		.pipe rename !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest path.join params.path, 'build/'

for name, item of browserify-data
	# parse relative paths in "shim"
	if item.shim
		new-shim = {}
		for key, shim-item of item.shim
			new-item = ^^shim-item
			for param-name, val of shim-item then if param-name is \relativePath
				new-item.path = path.join item.path, 'src/', val.relativePath
				delete new-item[param-name]
			new-shim[key] = new-item
		item.shim = new-shim

	params =
		path: item.path
		main-src: item.main-src
		build-file: item.build-file
		shim: item.shim or {}
		jshint-disabled: item.jshint-disabled and true or false
		jshint-params: item.jshint-params and item.jshint-params or null
		jshint-exclude: item.jshint-exclude and item.jshint-exclude or []

	if item.jshint-relative-exclude
		for exclude in item.jshint-relative-exclude
			params.jshint-exclude.push path.join item.path, 'src/', exclude

	pre-build-tasks = [\clean-browserify- + name]

	if not params.jshint-disabled
		gulp.task \browserify- + name + \-jshint, ->
			browserify-jshint-task name, params
		pre-build-tasks.push \browserify- + name + \-jshint

	gulp.task \clean-browserify- + name, ->
		browserify-clean-task name, params

	gulp.task \browserify- + name, pre-build-tasks, ->
		browserify-build-task name, params

	browserify-clean-tasks.push \clean-browserify- + name
	browserify-build-tasks.push \browserify- + name

gulp.task \clean-browserify, browserify-clean-tasks
gulp.task \browserify, browserify-build-tasks

# browserify }}}1

gulp.task \default [
	\sprites
	\less
	\browserify
]
