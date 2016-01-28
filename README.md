front-end-gulp
==============

Declarative front-end deploy tasks using [Gulp.js](https://github.com/gulpjs/gulp).

Independent Gulp wrapper that provides own
Gulp CLI tool named as `font-end-gulp`.

You can declare your front-end deploy tasks
in `front-end-tasks.json` file (see also [Usage](#usage)).

You also can use this tool with standard <b>Gulp</b>
with regular `gulpfile.js` tasks without any worries,
it works independently.

Usage
=====

TODO

Supported tasks types
---------------------

1. Sprites:
  1. [Spritesmith](https://github.com/Ensighten/spritesmith).
2. Styles:
  1. [Stylus](https://learnboost.github.io/stylus/);
  2. [Less](http://lesscss.org/).
3. Scripts:
  1. [Browserify](http://browserify.org/) (transforms supported,
    you can use [LiveScript](http://livescript.net),
    [CoffeeScript](http://coffeescript.org/), etc.)
4. HTML:
  1. [Jade](http://jade-lang.com/).

License
=======

[MIT](./LICENSE-MIT)
