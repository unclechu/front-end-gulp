/**
 * @author Viacheslav Lotsmanov
 * @license MIT (https://raw.githubusercontent.com/unclechu/front-end-gulp-pattern/master/LICENSE-MIT)
 * @see {@link https://github.com/unclechu/front-end-gulp-pattern|GitHub}
 */

require! {
	path
	fs

	yargs : {argv}

	gulp
	del
	\gulp-task-listing : tasks
	\gulp-callback : gcb
	\gulp-plumber : plumber
	\gulp-if : gulpif
	\gulp-rename : rename
	\gulp-sourcemaps : sourcemaps
}

pkg = require path.join process.cwd!, './package.json'

unless pkg.gulp?
	throw new Error 'No "gulp" key in package.json'

gulp.task \help, tasks

production = argv.production?

# ignore errors, will be enabled anyway by any watcher
ignore-errors = argv[\ignore-errors]?

supported-types =
	styles:
		\stylus
		\less
	scripts:
		\browserify
		...

watch-tasks = []
default-tasks = []
clean-tasks = []

# helpers {{{1

rename-build-file = (build-path, main-src, build-file) !->
	if build-path.basename is path.basename main-src, path.extname main-src
		build-path.extname = path.extname build-file
		build-path.basename = path.basename build-file, build-path.extname

# sync
init-task-iteration = (name, item, init-func) !->
	init-func name, item
	if item.sub-tasks then for sub-task-name, sub-task of item.sub-tasks
		sub-task-params = ^^item
		sub-task-params.sub-task = null
		for key, val of sub-task then sub-task-params[key] = val
		init-func name + \- + sub-task-name, sub-task-params, true

init-watcher-task = (
	sub-task
	watch-files
	add-to-watchers-list
	watch-task-name
	watchers-list
	build-task-name
) !->
	add-to-list = false
	if add-to-watchers-list is true
		add-to-list = true
	else if not sub-task and add-to-watchers-list is not false
		add-to-list = true

	gulp.task watch-task-name , !->
		ignore-errors := true
		gulp.watch watch-files , [ build-task-name ]

	if add-to-list then watchers-list.push watch-task-name

# sync
prepare-paths = (params, cb) !->
	dest-dir = path.join params.path, \build
	dest-dir = params.dest-dir if params.dest-dir?

	src-dir = path.join params.path, \src
	src-dir = params.src-dir if params.src-dir?

	src-file-path = path.join src-dir, params.main-src

	exists = fs.exists-sync src-file-path
	throw new Error "Source file '#src-file-path' is not exists" if not exists

	cb src-file-path, src-dir, dest-dir

check-for-supported-type = (category, type) !-->
	unless supported-types[category]?
		throw new Error "Unknown category: '#category'"
	unless type |> (in supported-types[category])
		throw new Error "Unknown #category type: '#type'"

typical-clean-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params

	if params.dest-dir?
		to-remove = path.join dest-dir, params.build-file
	else
		to-remove = dest-dir

	del to-remove, force: true, cb

# helpers }}}1

# sprites {{{1

sprites-clean-tasks = []
sprites-build-tasks = []
sprites-watch-tasks = []

sprites-data = pkg.gulp.sprites or {}

# helper
sprite-prepare-paths = (params, cb) !->
	img = {}
	data = {}

	unless params.path?
		if not params.img-src-dir? or not params.img-dest-dir? or not params.data-dest-dir?
			throw new Error 'Not enough parameters'
	else
		img.src-dir = path.join params.path, \src
		img.dest-dir = path.join params.path, \build
		data.dest-dir = path.join params.path, \build

	img.src-dir = params.img-src-dir if params.img-src-dir?
	img.dest-dir = params.img-dest-dir if params.img-dest-dir?
	data.dest-dir = params.data-dest-dir if params.data-dest-dir?

	img.build-file-path = path.join img.dest-dir, params.img-build-file
	data.build-file-path = path.join data.dest-dir, params.data-build-file

	img.public-path = img.build-file-path
	img.public-path = params.img-public-path if params.img-public-path?

	cb img, data

sprite-clean-task = (name, sprite-params, params, cb) !->
	(img, data) <-! sprite-prepare-paths params

	to-remove =
		data.build-file-path
		...

	if params.img-dest-dir?
		to-remove.push img.build-file-path
	else
		to-remove.push img.dest-dir

	del to-remove, force: true, cb

sprite-build-task = (name, sprite-params, params, cb) !->
	(img, data) <-! sprite-prepare-paths params

	sprite-data = gulp.src path.join img.src-dir, '*.png'
		.pipe gulpif ignore-errors, plumber errorHandler: cb
		.pipe (require \gulp.spritesmith) sprite-params

	ready =
		img: no
		data: no

	postCb = !->
		return if not ready.img or not ready.data
		cb!

	sprite-data.img
		.pipe gulp.dest img.dest-dir
		.pipe gcb !->
			ready.img = yes
			postCb!

	sprite-data.css
		.pipe gulp.dest data.dest-dir
		.pipe gcb !->
			ready.data = yes
			postCb!

sprite-get-name-by-mask = (name, s, mask)->
	reg = new RegExp "\\\#task-name\\\#", \g
	result = '' + mask .replace reg, name
	for item of s
		reg = new RegExp "\\\##item\\\#", \g
		result .= replace reg, s[item]
	result

sprite-init-tasks = (name, item, sub-task=false) !->
	params =
		path: item.path or null
		img-build-file: item.imgBuildFile or \build.png
		img-src-dir: item.imgSrcDir or null
		img-dest-dir: item.imgDestDir or null
		data-build-file: item.dataBuildFile or \build.json
		data-dest-dir: item.dataDestDir or null
		img-public-path: item.imgPublicPath or null
		data-item-name-mask: item.dataItemNameMask or 'sprite-#task-name#-#name#'

	(img, data) <-! sprite-prepare-paths params

	sprite-params =
		img-name: params.img-build-file
		css-name: params.data-build-file
		img-path: img.public-path
		padding: item.padding or 1
		algorithm: item.algorithm or \top-down
		img-opts: format: \png
		css-format: item.dataType or void # default detects by extension
		css-var-map: let name then (s) !->
			s.name = sprite-get-name-by-mask name, s, params.data-item-name-mask

	clean-task-name = \clean-sprite- + name
	build-task-name = \sprite- + name
	watch-task-name = build-task-name + \-watch

	pre-build-tasks =
		clean-task-name
		...

	if item.buildDeps?
		for task-name in item.buildDeps
			pre-build-tasks.push task-name

	gulp.task clean-task-name,
		let name, sprite-params, params
			(cb) !-> sprite-clean-task name, sprite-params, params, cb

	gulp.task build-task-name, pre-build-tasks,
		let name, sprite-params, params
			(cb) !-> sprite-build-task name, sprite-params, params, cb

	sprites-clean-tasks.push clean-task-name
	sprites-build-tasks.push build-task-name unless sub-task

	# watcher

	if item.watchFiles?
		watch-files = item.watchFiles
	else
		watch-files = path.join img.src-dir, '*.png'

	init-watcher-task(
		sub-task
		watch-files
		item.addToWatchersList
		watch-task-name
		sprites-watch-tasks
		build-task-name
	)

for name, item of sprites-data
	init-task-iteration name, item, sprite-init-tasks

if sprites-clean-tasks.length > 0
	gulp.task \clean-sprites, sprites-clean-tasks
	clean-tasks.push \clean-sprites
if sprites-build-tasks.length > 0
	gulp.task \sprites, sprites-build-tasks
	default-tasks.push \sprites
if sprites-watch-tasks.length > 0
	gulp.task \sprites-watch, sprites-watch-tasks
	watch-tasks.push \sprites-watch

# sprites }}}1

# styles {{{1

styles-clean-tasks = []
styles-build-tasks = []
styles-watch-tasks = []

styles-data = pkg.gulp.styles or {}

styles-clean-task = typical-clean-task

styles-build-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params

	options = compress: production

	source-maps = false
	if params.source-maps is true
		source-maps = true
	else if not production and params.source-maps is not false
		source-maps = true

	source-maps-as-plugin = false

	plugin = null

	switch
	| params.type is \stylus =>
		# stylus-shim
		if params.shim?
			options.use = []
			for module-path in params.shim
				options.use.push require path.join process.cwd!, module-path

		source-maps-as-plugin = true if source-maps
		plugin = require \gulp-stylus
	| params.type is \less =>
		source-maps-as-plugin = true if source-maps
		plugin = require \gulp-less
	| _ => ...

	gulp.src src-file-path
		.pipe gulpif ignore-errors, plumber errorHandler: cb
		.pipe gulpif source-maps-as-plugin, sourcemaps.init!
		.pipe plugin options
		.pipe gulpif source-maps-as-plugin, sourcemaps.write!
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest dest-dir
		.pipe gcb cb

styles-init-tasks = (name, item, sub-task=false) !->
	params =
		type: item.type
		path: item.path
		main-src: item.mainSrc
		src-dir: item.srcDir or null
		build-file: item.buildFile
		dest-dir: item.destDir or null
		shim: item.shim or null

	params.type |> check-for-supported-type \styles

	if typeof item.sourceMaps is \boolean
		params.source-maps = item.sourceMaps

	clean-task-name = \clean-styles- + name
	build-task-name = \styles- + name
	watch-task-name = build-task-name + \-watch

	pre-build-tasks =
		clean-task-name
		...

	if item.buildDeps?
		for task-name in item.buildDeps
			pre-build-tasks.push task-name

	gulp.task clean-task-name,
		let name, params
			(cb) !-> styles-clean-task name, params, cb

	gulp.task build-task-name, pre-build-tasks,
		let name, params
			(cb) !-> styles-build-task name, params, cb

	styles-clean-tasks.push clean-task-name
	styles-build-tasks.push build-task-name unless sub-task

	# watcher

	(src-file-path, src-dir) <-! prepare-paths params

	switch
	| item.watchFiles?     => watch-files = item.watchFiles
	| item.type is \less   => watch-files = path.join src-dir, '**/*.less'
	| item.type is \stylus =>
		watch-files =
			path.join src-dir, '**/*.styl'
			path.join src-dir, '**/*.stylus'
	| _ => ...

	init-watcher-task(
		sub-task
		watch-files
		item.addToWatchersList
		watch-task-name
		styles-watch-tasks
		build-task-name
	)

for name, item of styles-data
	init-task-iteration name, item, styles-init-tasks

if styles-clean-tasks.length > 0
	gulp.task \clean-styles, styles-clean-tasks
	clean-tasks.push \clean-styles
if styles-build-tasks.length > 0
	gulp.task \styles, styles-build-tasks
	default-tasks.push \styles
if styles-watch-tasks.length > 0
	gulp.task \styles-watch, styles-watch-tasks
	watch-tasks.push \styles-watch

# styles }}}1

# scripts {{{1

scripts-clean-tasks = []
scripts-build-tasks = []
scripts-watch-tasks = []

scripts-data = pkg.gulp.scripts or {}

scripts-clean-task = typical-clean-task

scripts-jshint-task = (name, params, cb) !->
	(src-file-path, src-dir) <-! prepare-paths params

	require! {
		\gulp-jshint : jshint
		\jshint-stylish : stylish
	}

	src =
		path.join src-dir, '**/*.js'
		...

	for exclude in params.jshint-exclude
		src.push \! + exclude

	gulp.src src
		.pipe jshint params.jshint-params
		.pipe jshint.reporter stylish
		.pipe rename \x # hack for end callback
		.end cb

scripts-build-browserify-task = (name, params, cb) !->
	options =
		shim: params.shim
		debug: false

	if params.debug is true
		options.debug = true
	else if not production and params.debug is not false
		options.debug = true

	options.transform = params.transform if params.transform?
	options.extensions = params.extensions if params.extensions?

	(src-file-path, src-dir, dest-dir) <-! prepare-paths params

	gulp.src src-file-path, read: false
		.pipe gulpif ignore-errors, plumber errorHandler: cb
		.pipe (require \gulp-browserify) options
		.pipe gulpif production, (require \gulp-uglify) preserveComments: \some
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest dest-dir
		.pipe gcb cb

scripts-init-tasks = (name, item, sub-task=false) !->
	params =
		type: item.type
		path: item.path
		main-src: item.mainSrc
		src-dir: item.srcDir or null
		build-file: item.buildFile
		dest-dir: item.destDir or null
		shim: item.shim or {}
		jshint-disabled: item.jshintDisabled and true or false
		jshint-params: item.jshintParams or null
		jshint-exclude: item.jshintExclude or []
		transform: item.transform or null
		extensions: item.extensions or null

	params.type |> check-for-supported-type \scripts

	(src-file-path, src-dir) <-! prepare-paths params

	# parse relative paths in "shim"
	if item.shim?
		for key, shim-item of params.shim
			for param-name, val of shim-item
				if param-name is \relativePath
					shim-item.path = path.join src-dir, val
					delete! shim-item[param-name]

	if item.jshintRelativeExclude
		for exclude in item.jshintRelativeExclude
			params.jshint-exclude.push path.join src-dir, exclude

	if typeof item.debug is \boolean
		params.debug = item.debug

	clean-task-name = \clean-scripts- + name
	build-task-name = \scripts- + name
	jshint-task-name = build-task-name + \-jshint
	watch-task-name = build-task-name + \-watch

	pre-build-tasks =
		clean-task-name
		...

	if item.buildDeps?
		for task-name in item.buildDeps
			pre-build-tasks.push task-name

	unless params.jshint-disabled
		gulp.task jshint-task-name,
			let name, params
				(cb) !-> scripts-jshint-task name, params, cb
		pre-build-tasks.push jshint-task-name

	gulp.task clean-task-name,
		let name, params
			(cb) !-> scripts-clean-task name, params, cb

	if item.type is \browserify
		gulp.task build-task-name, pre-build-tasks,
			let name, params
				(cb) !-> scripts-build-browserify-task name, params, cb
	else
		...

	scripts-clean-tasks.push clean-task-name
	scripts-build-tasks.push build-task-name unless sub-task

	# watcher

	switch
	| item.watchFiles?         => watch-files = item.watchFiles
	| item.type is \browserify =>
		watch-files =
			path.join src-dir, '**/*.js'
			...
		if params.extensions
			for ext in params.extensions
				watch-files.push path.join src-dir, '**/*' + ext
	| _ => ...

	init-watcher-task(
		sub-task
		watch-files
		item.addToWatchersList
		watch-task-name
		scripts-watch-tasks
		build-task-name
	)

for name, item of scripts-data
	init-task-iteration name, item, scripts-init-tasks

if scripts-clean-tasks.length > 0
	gulp.task \clean-scripts, scripts-clean-tasks
	clean-tasks.push \clean-scripts
if scripts-build-tasks.length > 0
	gulp.task \scripts, scripts-build-tasks
	default-tasks.push \scripts
if scripts-watch-tasks.length > 0
	gulp.task \scripts-watch, scripts-watch-tasks
	watch-tasks.push \scripts-watch

# scripts }}}1

# clean {{{1

clean-data = pkg.gulp.clean or []
dist-clean-data = pkg.gulp.distclean or []
dist-clean-tasks = []

if clean-data.length > 0 or clean-tasks.length > 0
	gulp.task \clean, clean-tasks, (cb) !-> del clean-data , cb
	dist-clean-tasks.push \clean

if dist-clean-tasks.length > 0 or dist-clean-data.length > 0
	gulp.task \distclean , dist-clean-tasks, (cb) !-> del dist-clean-data , cb

# clean }}}1

gulp.task \watch, watch-tasks if watch-tasks.length > 0
gulp.task \default default-tasks if default-tasks.length > 0
