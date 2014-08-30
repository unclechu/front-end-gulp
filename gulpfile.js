/**
 * @version r1
 * @author Viacheslav Lotsmanov
 */

var pkg = require('./package.json');

var path = require('path');

var gulp = require('gulp');
var argv = require('yargs').argv;

var clean = require('gulp-clean');
var spritesmith = require('gulp.spritesmith');
var taskListing = require('gulp-task-listing');
var less = require('gulp-less');
var gulpif = require('gulp-if');
var rename = require('gulp-rename');
var browserify = require('gulp-browserify');
var uglify = require('gulp-uglify');
var jshint = require('gulp-jshint');
var stylish = require('jshint-stylish');

gulp.task('help', taskListing);

var production = argv.production ? true : false;

// helpers {{{1

function renameBuildFile(buildPath, mainSrc, buildFile) { // {{{2
	if (buildPath.basename === path.basename(mainSrc, path.extname(mainSrc))) {
		buildPath.extname = path.extname(buildFile);
		buildPath.basename = path.basename(buildFile, buildPath.extname);
	}
} // renameBuildFile() }}}2

// helpers }}}1

// clean {{{1

function cleanTask(list) { // {{{2
	if (!Array.isArray(list)) return gulp;
	var retval = null;
	list.forEach(function (item) {
		retval = gulp.src(item).pipe(clean({ force: true }));
	});
	return retval;
} // cleanTask() }}}2

gulp.task('clean', ['clean-sprites'], function () {
	return cleanTask(pkg.gulp.clean);
});

gulp.task('distclean', ['clean'], function () {
	return cleanTask(pkg.gulp.distclean);
});

// clean }}}1

// sprites {{{1

var spritesCleanTasks = [];
var spritesBuildTasks = [];

function spriteCleanTask(name, spriteParams, params) { // {{{2
	gulp
		.src(path.join(params.imgDir, 'build/'))
		.pipe(clean({ force: true }));
	return gulp
		.src(path.join(params.cssDir, spriteParams.cssName))
		.pipe(clean({ force: true }));
} // spriteCleanTask() }}}2

function spriteBuildTask(name, spriteParams, params) { // {{{2
	var spriteData = gulp
		.src(path.join(params.imgDir, 'src/*.png'))
		.pipe(spritesmith( spriteParams ));

	spriteData.img.pipe(gulp.dest(path.join(params.imgDir, 'build/')));
	return spriteData.css.pipe(gulp.dest( params.cssDir ));
} // spriteBuildTask() }}}2

// create tasks by package.json {{{2
Object.keys(pkg.gulp.sprites).forEach(function (name) {
	var item = pkg.gulp.sprites[name];

	var imgName = item.img_name || 'sprite.png';
	var spriteParams = {
		imgName: imgName,
		cssName: item.css_name || name + '.css',
		imgPath: path.join(item.img_path_prefix, 'build/', imgName),
		padding: item.padding || 1,
		imgOpts: { format: 'png' },
		cssVarMap: function (s) {
			s.name = 'sprite_' + name + '_' + s.name;
		},
		algorithm: item.algorithm || 'top-down',
	};

	var params = {
		imgDir: item.img_dir,
		cssDir: item.css_dir,
	};

	gulp.task(
		'clean-sprite-' + name,
		spriteCleanTask.bind(null, name, spriteParams, params)
	);
	gulp.task(
		'sprite-' + name,
		['clean-sprite-' + name],
		spriteBuildTask.bind(null, name, spriteParams, params)
	);

	spritesCleanTasks.push('clean-sprite-' + name);
	spritesBuildTasks.push('sprite-' + name);
}); // create tasks by package.json }}}2

gulp.task('clean-sprites', spritesCleanTasks);
gulp.task('sprites', spritesBuildTasks);

// sprites }}}1

// less {{{1

var lessCleanTasks = [];
var lessBuildTasks = [];

function lessCleanTask(name, params) { // {{{2
	return gulp
		.src(path.join(params.path, 'build/'))
		.pipe(clean({ force: true }));
} // lessCleanTask() }}}2

function lessBuildTask(name, params) { // {{{2
	return gulp
		.src(path.join(params.path, 'src/', params.mainSrc))
		.pipe(less({
			compress: production,
		}))
		.pipe(rename(function (buildPath) {
			renameBuildFile(buildPath, params.mainSrc, params.buildFile);
		}))
		.pipe(gulp.dest(path.join(params.path, 'build/')));
} // lessBuildTask() }}}2

// create tasks by package.json {{{2
Object.keys(pkg.gulp.less).forEach(function (name) {
	var item = pkg.gulp.less[name];

	var params = {
		path: item.path,
		mainSrc: item.main_src,
		buildFile: item.build_file,
	};

	var requiredSprites = [];
	if (item.required_sprites)
		item.required_sprites.forEach(function (spriteName) {
			requiredSprites.push('sprite-' + spriteName);
		});

	gulp.task(
		'clean-less-' + name,
		requiredSprites,
		lessCleanTask.bind(null, name, params)
	);
	gulp.task(
		'less-' + name,
		['clean-less-' + name],
		lessBuildTask.bind(null, name, params)
	);

	lessCleanTasks.push('clean-less-' + name);
	lessBuildTasks.push('less-' + name);
}); // create tasks by package.json }}}2

gulp.task('clean-less', lessCleanTasks);
gulp.task('less', lessBuildTasks);

// less }}}1

// browserify {{{1

var browserifyCleanTasks = [];
var browserifyBuildTasks = [];

function browserifyCleanTask(name, params) { // {{{2
	return gulp
		.src(path.join(params.path, 'build/'))
		.pipe(clean({ force: true }));
} // browserifyCleanTask() }}}2

function browserifyJSHintTask(name, params) { // {{{2
	var src = [ path.join(params.path, 'src/**/*.js') ];
	params.jshintExclude.forEach(function (exclude) {
		src.push('!' + exclude);
	});
	return gulp
		.src(src)
		.pipe(jshint(params.jshintParams))
		.pipe(jshint.reporter(stylish));
} // browserifyJSHintTask() }}}2

function browserifyBuildTask(name, params) { // {{{2
	return gulp
		.src(path.join(params.path, 'src/', params.mainSrc))
		.pipe(browserify({
			shim: params.shim,
			debug: !production,
		}))
		.pipe(gulpif(production, uglify({
			preserveComments: 'some',
		})))
		.pipe(rename(function (buildPath) {
			renameBuildFile(buildPath, params.mainSrc, params.buildFile);
		}))
		.pipe(gulp.dest(path.join(params.path, 'build/')));
} // browserifyBuildTask() }}}2

// create tasks by package.json {{{2
Object.keys(pkg.gulp.browserify).forEach(function (name) {
	var item = pkg.gulp.browserify[name];

	if (item.shim) Object.keys(item.shim).forEach(function (key) {
		Object.keys(item.shim[key]).forEach(function (paramName) {
			if (paramName === 'relative_path') {
				item.shim[key]['path'] = path.join(
					item.path, 'src/', item.shim[key][paramName]);
				delete item.shim[key][paramName];
			}
		});
	});

	var params = {
		path: item.path,
		mainSrc: item.main_src,
		buildFile: item.build_file,
		shim: item.shim || {},
		jshintDisabled: item.jshint_disabled ? true : false,
		jshintParams: item.jshint_params ? item.jshint_params : null,
		jshintExclude: item.jshint_exclude ? item.jshint_exclude : [],
	};

	if (item.jshint_relative_exclude)
		item.jshint_relative_exclude.forEach(function (exclude) {
			params.jshintExclude.push(
				path.join(item.path, 'src/', exclude));
		});

	var preBuildTasks = ['clean-browserify-' + name];

	if (!params.jshintDisabled) {
		gulp.task(
			'browserify-' + name + '-jshint',
			browserifyJSHintTask.bind(null, name, params)
		);
		preBuildTasks.push('browserify-' + name + '-jshint');
	}

	gulp.task(
		'clean-browserify-' + name,
		browserifyCleanTask.bind(null, name, params)
	);
	gulp.task(
		'browserify-' + name,
		preBuildTasks,
		browserifyBuildTask.bind(null, name, params)
	);

	browserifyCleanTasks.push('clean-browserify-' + name);
	browserifyBuildTasks.push('browserify-' + name);
}); // create tasks by package.json }}}2

gulp.task('clean-browserify', browserifyCleanTasks);
gulp.task('browserify', browserifyBuildTasks);

// browserify }}}1

gulp.task('default', [
	'sprites',
	'less',
	'browserify'
]);
