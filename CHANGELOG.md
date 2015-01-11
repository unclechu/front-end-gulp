Changelog
=========

1.0.0 / 2015-01-11
------------------

1. Browserify transforms now provided by `package.json`, no longer need to
   modify `front-end-gulp-pattern` for support new transform
   (see for "transform" and "extensions" keys in `package.json`).

0.0.1 / 2015-01-09
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

r11 / 2015-01-08
----------------

1. More abstractions in code instead of copy-paste blocks;
2. Fixed sources paths for watchers (custom sources paths support).

r10 / 2015-01-08
----------------

1. Added "shim" option support for "stylus" styles tasks as array of paths to
   modules that return plugin callback (like "nib").

r9 / 2015-01-06
---------------

1. Exceptions for not existing main source files for scripts and styles tasks;
2. Support custom sources paths for scripts and styles tasks.
   Sub-directories "src" and "build" is no longer required;
3. Added builded **gulpfile.js**.
