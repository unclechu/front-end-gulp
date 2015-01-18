front-end-gulp-pattern
======================

`gulp-cli` wrapper with own read-only `gulpfile` for front-end.

Provides own `gulp-cli` binary as `font-end-gulp`.

Should be configured by `package.json`.

Usage
=====

1. Create `package.json` file in root of your project;

2. You should set <i>"dependencies"</i>, <i>"postinstall"</i> script and <i>"gulp"</i> hash for your `front-end-gulp` tasks;

  1. Minimal example of `package.json`:
    ```json
    {
      "dependencies": {
        "front-end-gulp-pattern": "^1"
      },
      "scripts": {
        "postinstall": "./node_modules/.bin/front-end-gulp --production"
      },
      "gulp": {
        "distclean": [
          "./node_modules"
        ]
      }
    }
    ```

  2. After `npm install` `front-end-gulp` will do nothing, but you can run:
    ```
    ./node_modules/.bin/front-end-gulp distclean
    ```
    to remove `node_modules` directory;

  3. If you're using <b>git</b> then you should add `node_modules` to `.gitignore`;
  4. `--production` flag will minify styles and scripts;
  5. Also you can use it with [web-front-end-deploy](https://github.com/unclechu/web-front-end-deploy) as git-submodule, do it in root of your project:

    ```bash
    $ git submodule add https://github.com/unclechu/web-front-end-deploy
    $ ln -s ./web-front-end-deploy/deploy.sh
    $ mkdir _deploy
    $ cd _deploy
    $ ln -s ../web-front-end-deploy/tasks/11-front-end-gulp-pattern_symbolic_link.sh
    $ ln -s ../web-front-end-deploy/tasks/13-front-end-gulp-pattern_default_tasks.sh
    $ cd ..
    ```

    And set <i>"postinstall"</i> key in key <i>"scripts"</i> of `package.json` to: "./deploy.sh".
    `13-front-end-gulp-pattern_default_tasks.sh` will do:
    ```
    ./node_modules/.bin/front-end-gulp --production
    ```
    And `11-front-end-gulp-pattern_symbolic_link.sh` will create symbolic link `front-end-gulp` to `./node_modules/.bin/front-end-gulp` in root of your project. In this case you should add `front-end-gulp` to `.gitignore` and to <i>"distclean"</i>:
    
    ```json
    {
      "dependencies": {
        "front-end-gulp-pattern": "^1"
      },
      "scripts": {
        "postinstall": "./deploy.sh"
      },
      "gulp": {
        "distclean": [
          "./node_modules",
          "./front-end-gulp"
        ]
      }
    }
    ```

This doc in working process...

Supported tasks types
---------------------

1. Sprites ([spritesmith](https://github.com/Ensighten/spritesmith));
2. Styles:
  1. [Stylus](https://learnboost.github.io/stylus/);
  2. [Less](http://lesscss.org/).
3. Scripts:
  1. [Browserify](http://browserify.org/) (transforms supported, you can use [LiveScript](http://livescript.net), [CoffeeScript](http://coffeescript.org/), etc.)

License
=======

[GNU/GPLv3](./LICENSE)
