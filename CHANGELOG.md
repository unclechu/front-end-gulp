Changelog
=========

2.0.0 / TODO TODO 2016
------------------

1.  License changed from `GPLv3` to `MIT`;
2.  <b>WARNING!</b> Separated tasks declaring to own json-file named as
    `front-end-tasks.json`;
3.  <b>WARNING!</b> In scripts tasks field `jshintDisabled` renamed to `jshintEnabled`;
4.  <b>WARNING!</b> In scripts tasks JSHint disabled by default;
5.  <b>WARNING!</b> Sprites task now must have `type` field with at least `'spritesmith'`;
6.  <b>WARNING!</b> New action prefixes for tasks names separated with symbol `:`
    `clean:scripts` instead of `clean-scripts`,
    `watch:scripts` instead of `scripts-watch`;
7.  Support `HTML` building by `Jade` sources;
8.  New optional param `cleanTarget` to replace default clean behavior with just
    removing target directory;
9.  Some code refactoring;
10. LiveScript 1.4;
11. Updated some dependencies versions;
12. Added `--minify` and `--pretty` flags to forcing uglify/minify
    or prevent it even if it's production mode or declared by task;
13. Support custom json-config file by `--tasks-json=*.json` argument;
14. Custom task parameters specific for production mode,
    that extend current task parameters (works like sub-tasks).

1.0.1 / 11 Jan 2015
-------------------

1. Fixes for `gulp-stylus` that broke backward compatibility, sourcemaps
   now provides by `gulp-sourcemaps` (as plugin).

1.0.0 / 11 Jan 2015
-------------------

1. Browserify transforms now provided by `package.json`, no longer need to
   modify `front-end-gulp-pattern` for support new transform
   (see for "transform" and "extensions" keys in `package.json`).

0.0.1 / 9 Jan 2015
------------------

1. Fixed bugs with custom sources paths for scripts tasks;
2. Fixed bugs with custom sources paths for styles tasks;
3. Module "prelude-ls" is no longer required for "liveify" scripts task type;
4. Module "nib" is no longer required for "stylus" styles task type;
5. Code refactoring;
6. Optional modules which provides by your application dependencies;
7. `gulp-cli` wrapper;
8. Broken backward compatibility for sprites `package.json` keys for unified
   keys names style, also new keys available;
9. Updated dependencies versions;
10. Watcher for sprites;
11. Empty tasks removing;
12. NPM package.

r11 / 8 Jan 2015
----------------

1. More abstractions in code instead of copy-paste blocks;
2. Fixed sources paths for watchers (custom sources paths support).

r10 / 8 Jan 2015
----------------

1. Added "shim" option support for "stylus" styles tasks as array of paths to
   modules that return plugin callback (like "nib").

r9 / 6 Jan 2015
---------------

1. Exceptions for not existing main source files for scripts and styles tasks;
2. Support custom sources paths for scripts and styles tasks.
   Sub-directories "src" and "build" is no longer required;
3. Added builded **gulpfile.js**.
