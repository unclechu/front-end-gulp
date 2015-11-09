/**
 * @author Viacheslav Lotsmanov
 * @license MIT (https://raw.githubusercontent.com/unclechu/front-end-gulp-pattern/master/LICENSE-MIT)
 * @see {@link https://github.com/unclechu/front-end-gulp-pattern|GitHub}
 */

require! {
	path
	fs
	
	yargs
	
	gulp
	del
	\vinyl-paths
	\gulp-task-listing : tasks
	\gulp-callback     : gcb
	\gulp-plumber      : plumber
	\gulp-if           : gulpif
	\gulp-rename       : rename
	\gulp-sourcemaps   : sourcemaps
}

const argv = do
	yargs
		.default do
			production: false
			ignore-errors: false
		.boolean \production
		.boolean \ignore-errors
		.argv

const pkg = require path.join process.cwd!, \package.json

unless pkg.gulp?
	throw new Error 'No "gulp" key in package.json'

gulp.task \help, tasks

const is-production-mode = argv.production

# ignore errors, will be enabled anyway by any watcher
ignore-errors = argv.ignore-errors

const supported-types =
	sprites:
		\spritesmith
		...
	styles:
		\stylus
		\less
	scripts:
		\browserify
		...
	html:
		\jade
		...

watch-tasks   = []
default-tasks = []
clean-tasks   = []

# helpers {{{1

const rename-build-file = (build-path, main-src, build-file) !->
	if build-path.basename is path.basename main-src, path.extname main-src
		build-path.extname  = path.extname build-file
		build-path.basename = path.basename build-file, build-path.extname

# sync
const init-task-iteration = (name, item, init-func) !->
	init-func name, item
	return unless item.sub-tasks?
	for sub-task-name, sub-task of item.sub-tasks
		const sub-task-params = ^^item <<<< { sub-task: null } <<<< sub-task
		init-func "#{name}-#{sub-task-name}", sub-task-params, true

const init-watcher-task = (
	sub-task
	watch-files
	add-to-watchers-list
	watch-task-name
	watchers-list
	build-task-name
) !->
	const add-to-list =
		(add-to-watchers-list is true)
		or (not sub-task and add-to-watchers-list isnt false)
	
	gulp.task watch-task-name, !->
		ignore-errors := true
		gulp.watch watch-files, [ build-task-name ]
	
	watchers-list.push watch-task-name if add-to-list

# sync
const prepare-paths = (params, cb) !->
	const dest-dir = params.dest-dir ? path.join params.path, \build
	const src-dir  = params.src-dir  ? path.join params.path, \src
	
	# ?String
	const src-file-path =
		if params.main-src?
			path.join src-dir, params.main-src
		else
			null
	
	if src-file-path? and (not fs.exists-sync src-file-path)
		throw new Error "Source file '#src-file-path' isn't exists"
	
	cb src-file-path, src-dir, dest-dir

const check-for-supported-type = (category, type) !-->
	unless supported-types[category]?
		throw new Error "Unknown category: '#category'"
	unless type |> (in supported-types[category])
		throw new Error "Unknown #category type: '#type'"

const rm-it = (to-remove, cb) ->
	del to-remove, force: true
		.then cb.bind null, null
		.catch cb.bind null

const typical-clean-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params
	rm-it _, cb <| switch
		| params.clean-dir? => params.clean-dir
		| params.dest-dir?  => path.join dest-dir, params.build-file
		| otherwise         => dest-dir

# helpers }}}1

# sprites {{{1

sprites-clean-tasks = []
sprites-build-tasks = []
sprites-watch-tasks = []

const sprites-data = pkg.gulp.sprites ? {}

# helper
const sprite-prepare-paths = (params, cb) !->
	img  = Object.create null
	data = Object.create null
	
	unless params.path?
		if (not params.img-src-dir?)
		or (not params.img-dest-dir?)
		or (not params.data-dest-dir?)
			throw new Error 'Not enough parameters'
	else
		img.src-dir   = path.join params.path, \src
		img.dest-dir  = path.join params.path, \build
		data.dest-dir = path.join params.path, \build
	
	img.src-dir   = params.img-src-dir   if params.img-src-dir?
	img.dest-dir  = params.img-dest-dir  if params.img-dest-dir?
	data.dest-dir = params.data-dest-dir if params.data-dest-dir?
	
	img.build-file-path  = path.join img.dest-dir,  params.img-build-file
	data.build-file-path = path.join data.dest-dir, params.data-build-file
	
	img.public-path = img.build-file-path
	img.public-path = params.img-public-path if params.img-public-path?
	
	cb img, data

const sprite-clean-task = (name, sprite-params, params, cb) !->
	(img, data) <-! sprite-prepare-paths params
	
	rm-it _, cb <| switch
	| params.clean-dir? => params.clean-dir
	| otherwise => [ data.build-file-path ] ++
		[ params.img-dest-dir? and img.build-file-path or img.dest-dir ]

const sprite-build-task = (name, sprite-params, params, cb) !->
	require! {
		\gulp.spritesmith : spritesmith
	}
	
	(img, data) <-! sprite-prepare-paths params
	
	const sprite-data =
		gulp.src path.join img.src-dir, \*.png
			.pipe gulpif ignore-errors, plumber error-handler: cb
			.pipe spritesmith sprite-params
	
	ready =
		img: no
		data: no
	
	const post-cb = !-> do cb if ready.img and ready.data
	
	sprite-data.img
		.pipe gulp.dest img.dest-dir
		.pipe gcb !->
			ready.img = yes
			do post-cb
	
	sprite-data.css
		.pipe gulp.dest data.dest-dir
		.pipe gcb !->
			ready.data = yes
			do post-cb

const sprite-get-name-by-mask = (name, s, mask) ->
	Object.keys s .reduce (result, key) ->
		result.replace (new RegExp "\\##{key}\\#", \g), s[key]
	, mask.replace (new RegExp '\\#task-name\\#', \g), name

const sprite-init-tasks = (name, item, sub-task=false) !->
	const params =
		type                : item.type
		path                : item.path                or null
		img-build-file      : item.img-build-file      or \build.png
		img-src-dir         : item.img-src-dir         or null
		img-dest-dir        : item.img-dest-dir        or null
		data-build-file     : item.data-build-file     or \build.json
		data-dest-dir       : item.data-dest-dir       or null
		img-public-path     : item.img-public-path     or null
		data-item-name-mask : item.data-item-name-mask or \sprite-#task-name#-#name#
		clean-dir           : item.clean-dir ? null
	
	params.type |> check-for-supported-type \sprites
	
	(img) <-! sprite-prepare-paths params
	
	const sprite-params =
		img-name    : params.img-build-file
		css-name    : params.data-build-file
		img-path    : img.public-path
		padding     : item.padding or 1
		algorithm   : item.algorithm or \top-down
		img-opts    : format: \png
		css-format  : item.data-type or void # default detects by extension
		css-var-map : let name then (s) !->
			s.name = sprite-get-name-by-mask name, s, params.data-item-name-mask
	
	const clean-task-name = "clean-sprite-#name"
	const build-task-name = "sprite-#name"
	const watch-task-name = "#{build-task-name}-watch"
	
	const pre-build-tasks = [ clean-task-name ] ++ (item.build-deps ? [])
	
	gulp.task clean-task-name,
		let name, sprite-params, params
			(cb) !-> sprite-clean-task name, sprite-params, params, cb
	
	gulp.task build-task-name, pre-build-tasks,
		let name, sprite-params, params
			(cb) !-> sprite-build-task name, sprite-params, params, cb
	
	sprites-clean-tasks.push clean-task-name
	sprites-build-tasks.push build-task-name unless sub-task
	
	# watcher
	
	const watch-files = item.watch-files ? path.join img.src-dir, \*.png
	
	init-watcher-task(
		sub-task
		watch-files
		item.add-to-watchers-list
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

const styles-data = pkg.gulp.styles ? {}

const styles-clean-task = typical-clean-task

const styles-build-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params
	
	const options = (Object.create null)
		<<< { compress: is-production-mode }
		<<< (
			if (params.type is \stylus) and params.shim?
				use: [ (require path.join process.cwd!, ..) for params.shim ]
			else if (params.type is \less) and params.shim?
				...
			else
				{}
		)
	
	const source-maps =
		(params.source-maps is on)
		or ((not is-production-mode) and (params.source-maps isnt off))
	
	const plugin = switch params.type
		| \stylus => require \gulp-stylus
		| \less   => require \gulp-less
		| _       => ...
	
	gulp.src src-file-path
		.pipe gulpif ignore-errors, plumber error-handler: cb
		.pipe gulpif source-maps, sourcemaps.init!
		.pipe plugin options
		.pipe gulpif source-maps, sourcemaps.write!
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest dest-dir
		.pipe gcb cb

const styles-init-tasks = (name, item, sub-task=false) !->
	const params =
		do
			type       : item.type
			path       : item.path
			main-src   : item.main-src
			src-dir    : item.src-dir or null
			build-file : item.build-file
			dest-dir   : item.dest-dir or null
			shim       : item.shim or null
			clean-dir  : item.clean-dir ? null
		<<< ((typeof item.source-maps is \boolean) and { item.source-maps } or {})
	
	params.type |> check-for-supported-type \styles
	
	const clean-task-name = "clean-styles-#name"
	const build-task-name = "styles-#name"
	const watch-task-name = "#{build-task-name}-watch"
	
	const pre-build-tasks = [ clean-task-name ] ++ (item.build-deps ? [])
	
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
	
	const watch-files = switch
		| item.watch-files?    => item.watch-files
		| item.type is \less   => path.join src-dir, \**/*.less
		| item.type is \stylus =>
			<[ **/*.styl **/*.stylus ]> .map (-> path.join src-dir, it)
		| _ => ...
	
	init-watcher-task(
		sub-task
		watch-files
		item.add-to-watchers-list
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

const scripts-data = pkg.gulp.scripts ? {}

const scripts-clean-task = typical-clean-task

const scripts-jshint-task = (name, params, cb) !->
	(src-file-path, src-dir) <-! prepare-paths params
	
	require! {
		\gulp-jshint    : jshint
		\jshint-stylish : stylish
	}
	
	const src =
		[ path.join src-dir, \**/*.js ] ++
			[ "!#{..}" for params.jshint-exclude ]
	
	gulp.src src
		.pipe jshint params.jshint-params
		.pipe jshint.reporter stylish
		.pipe rename \x # hack for end callback
		.end cb

const scripts-build-browserify-task = (name, params, cb) !->
	const options =
		do
			shim: params.shim
			debug:
				(params.debug is true)
				or ((not is-production-mode) and (params.debug isnt false))
		<<< (params.transform?  and { params.transform  } or {})
		<<< (params.extensions? and { params.extensions } or {})
	
	require! {
		\gulp-browserify : browserify
		\gulp-uglify     : uglify
	}
	
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params
	
	gulp.src src-file-path, read: false
		.pipe gulpif ignore-errors, plumber error-handler: cb
		.pipe browserify options
		.pipe gulpif is-production-mode, uglify preserve-comments: \some
		.pipe rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest dest-dir
		.pipe gcb cb

# String -> ?Object -> Object
const scripts-expand-relative-shim-paths = (src-dir, shim ? {}) ->
	(result, name) <- Object.keys shim .reduce _, {}
	(<<< result) <| (-> { "#name": it }) <|
	unless shim[name].relative-path?
		shim[name]
	else
		(shim-item, param) <- Object.keys shim[name] .reduce _, {}
		const val = shim[name][param]
		
		if param is \relativePath
			shim-item.path = path.join src-dir, val
		else
			shim-item[param] = val
		
		shim-item

const scripts-init-tasks = (name, item, sub-task=false) !->
	const src-params =
		do
			type           : item.type
			path           : item.path
			main-src       : item.main-src
			src-dir        : item.src-dir or null
			build-file     : item.build-file
			dest-dir       : item.dest-dir or null
			jshint-enabled : !!item.jshint-enabled
			jshint-params  : item.jshint-params or null
			transform      : item.transform or null
			extensions     : item.extensions or null
			clean-dir      : item.clean-dir ? null
		<<< ((typeof item.debug is \boolean) and { item.debug } or {})
	
	src-params.type |> check-for-supported-type \scripts
	
	(src-file-path, src-dir) <-! prepare-paths src-params
	
	const params =
		{} <<< src-params
		<<< { shim: scripts-expand-relative-shim-paths src-dir, item.shim }
		<<< {
			jshint-exclude:
				(item.jshint-exclude or []) ++
					[ (path.join src-dir, ..) for (item.jshint-relative-exclude or []) ]
		}
	
	const clean-task-name  = "clean-scripts-#name"
	const build-task-name  = "scripts-#name"
	const jshint-task-name = "#{build-task-name}-jshint"
	const watch-task-name  = "#{build-task-name}-watch"
	
	const pre-build-tasks =
		[ clean-task-name ] ++
			(item.build-deps ? []) ++
			(params.jshint-enabled and [jshint-task-name] or [])
	
	if params.jshint-enabled
		gulp.task jshint-task-name,
			let name, params
				(cb) !-> scripts-jshint-task name, params, cb
	
	gulp.task clean-task-name,
		let name, params
			(cb) !-> scripts-clean-task name, params, cb
	
	switch item.type
	| \browserify =>
		gulp.task build-task-name, pre-build-tasks,
			let name, params
				(cb) !-> scripts-build-browserify-task name, params, cb
	| _ =>
		...
	
	scripts-clean-tasks.push clean-task-name
	scripts-build-tasks.push build-task-name unless sub-task
	
	# watcher
	
	const watch-files = switch
		| item.watch-files?        => item.watch-files
		| item.type is \browserify =>
			(path.join src-dir, \**/*.js) ++
				[ (path.join src-dir, "**/*#{..}") for (params.extensions or []) ]
		| _ => ...
	
	init-watcher-task(
		sub-task
		watch-files
		item.add-to-watchers-list
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

# html {{{1

html-clean-tasks = []
html-build-tasks = []
html-watch-tasks = []

const html-data = pkg.gulp.html ? {}

const html-get-files-selector = (src-dir ? '', params) -->
	switch params.type
	| \jade => [ path.join src-dir, \**/*.jade ]
	| _     => ...

const html-clean-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params
	
	switch
	| params.clean-dir? => rm-it params.clean-dir, cb
	| params.dest-dir? and (not src-file-path?) =>
		gulp
			.src (html-get-files-selector null, params), do
				base: src-dir
				read: false
			.pipe rename (build-path) !-> build-path.extname = \.html
			.pipe gulp.dest dest-dir
			.pipe vinyl-paths del
			.on \finish, !-> do cb
	| otherwise =>
		rm-it _, cb <| switch
			| params.dest-dir? => path.join dest-dir, params.build-file
			| otherwise        => dest-dir

const html-build-task = (name, params, cb) !->
	(src-file-path, src-dir, dest-dir) <-! prepare-paths params
	
	const options = (Object.create null)
		<<< { pretty: (params.pretty is on) }
		<<< (params.locals? and { params.locals } or {})
	
	const source-maps =
		(params.source-maps is on)
		or ((not is-production-mode) and (params.source-maps isnt off))
	
	const plugin = switch params.type
		| \jade => require \gulp-jade
		| _     => ...
	
	const is-single-file = params.main-src? and params.build-file?
	
	const src = src-file-path ? html-get-files-selector src-dir, params
	
	has-err = false
	gulp.src src
		.pipe gulpif ignore-errors, plumber error-handler: !->
			cb ... unless has-err
			has-err := true
		.pipe gulpif source-maps, sourcemaps.init!
		.pipe plugin options
		.pipe gulpif source-maps, sourcemaps.write!
		.pipe gulpif is-single-file, rename (build-path) !->
			rename-build-file build-path, params.main-src, params.build-file
		.pipe gulp.dest dest-dir
		.on \finish, !-> do cb unless has-err

const html-init-tasks = (name, item, sub-task=false) !->
	const params =
		do
			type       : item.type
			path       : item.path
			main-src   : item.main-src   or null
			src-dir    : item.src-dir    or null
			build-file : item.build-file or null
			dest-dir   : item.dest-dir   or null
			pretty     : item.pretty    ? null
			locals     : item.locals    ? null
			clean-dir  : item.clean-dir ? null
		<<< ((typeof item.source-maps is \boolean) and { item.source-maps } or {})
	
	params.type |> check-for-supported-type \html
	
	const clean-task-name = "clean-html-#name"
	const build-task-name = "html-#name"
	const watch-task-name = "#{build-task-name}-watch"
	
	const pre-build-tasks = [ clean-task-name ] ++ (item.build-deps ? [])
	
	gulp.task clean-task-name,
		let name, params
			(cb) !-> html-clean-task name, params, cb
	
	gulp.task build-task-name, pre-build-tasks,
		let name, params
			(cb) !-> html-build-task name, params, cb
	
	html-clean-tasks.push clean-task-name
	html-build-tasks.push build-task-name unless sub-task
	
	# watcher
	
	(src-file-path, src-dir) <-! prepare-paths params
	
	const watch-files = switch
		| item.watch-files?  => item.watch-files
		| item.type is \jade => path.join src-dir, \**/*.jade
		| _ => ...
	
	init-watcher-task(
		sub-task
		watch-files
		item.add-to-watchers-list
		watch-task-name
		html-watch-tasks
		build-task-name
	)

for name, item of html-data
	init-task-iteration name, item, html-init-tasks

if html-clean-tasks.length > 0
	gulp.task \clean-html, html-clean-tasks
	clean-tasks.push \clean-html
if html-build-tasks.length > 0
	gulp.task \html, html-build-tasks
	default-tasks.push \html
if html-watch-tasks.length > 0
	gulp.task \html-watch, html-watch-tasks
	watch-tasks.push \html-watch

# html }}}1

# clean {{{1

const clean-data = pkg.gulp.clean ? []
const dist-clean-data = pkg.gulp.distclean ? []

dist-clean-tasks = []

if (clean-data.length > 0) or (clean-tasks.length > 0)
	gulp.task \clean, clean-tasks, (cb) !-> rm-it clean-data, cb
	dist-clean-tasks.push \clean

if (dist-clean-tasks.length > 0) or (dist-clean-data.length > 0)
	gulp.task \distclean, dist-clean-tasks, (cb) !-> rm-it dist-clean-data, cb

# clean }}}1

gulp.task \watch, watch-tasks if watch-tasks.length > 0
gulp.task \default, default-tasks
