name: \front-end-gulp-pattern
version: '0.0.1'

description: 'gulp-cli wrapper with own read-only gulpfile for front-end.'
keywords:
	\gulp
	\stylus
	\less
	\browserify
	\livescript
	\ls
	\liveify
	\jshint
	\pattern
	\front-end
	\sprite
	\css

bin:
	\front-end-gulp : './bin/gulp-wrapper'

author: 'Viacheslav Lotsmanov <lotsmanov89@gmail.com>'
bugs: 'https://github.com/unclechu/front-end-gulp-pattern/issues'
licenses:
	type: 'GNU/GPLv3'
	url: 'https://raw.githubusercontent.com/unclechu/front-end-gulp-pattern/master/LICENSE'
	...

repository:
	type: \git
	url: 'https://github.com/unclechu/front-end-gulp-pattern'

dependencies:
	\yargs : '^1'
	\gulp : '^3'
	\gulp-cli : '~0.1.3'
	\del : '^1'
	\gulp-task-listing : '^1'
	\gulp-callback : '~0.0.3'
	\gulp-plumber : '~0.6.6'
	\gulp-if : '^1'
	\gulp-rename : '^1'
	\gulp-sourcemaps : '^1'

dev-dependencies:
	\LiveScript : '1.3.1'

	\gulp.spritesmith : '^1'

	\gulp-stylus : '^1'
	\gulp-less : '^1'

	\gulp-browserify : '~0.5'
	\liveify : '1.3.1'
	\gulp-uglify : '^1'
	\gulp-jshint : '^1'
	\jshint-stylish : '^1'

engines:
	node: '>= 0.10'

directories:
	bin: './bin/'
files:
	'bin/gulp-wrapper'
	\LICENSE
	\README.md
	\gulpfile.js
