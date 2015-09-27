Nim Makefile [![Build Status](https://travis-ci.org/Nycto/NimMakefile.svg?branch=master)](https://travis-ci.org/Nycto/NimMakefile)
============

A common Makefile for building Nim projects.

Features
--------

* Building and running tests in the `test` folder
* Building any binaries in the `bin` folder
* Compiling any code embedded in the `README.md`
* Watching for changes and recompiling via `make watch`
* Dependency analysis to reduce unnecessary rebuilds
* Setting up the environment for a Travis CI build (see below)

Install
-------

You can add this Makefile to your project with the following commands:

```
git submodule add https://github.com/Nycto/NimMakefile;
echo '$(shell git submodule update --init NimMakefile)' > Makefile;
echo 'include NimMakefile/makefile.mk' >> Makefile;
```

Once that is done, you can run `make` to compile your Nim project.

Travis CI Integration
---------------------

To support building your Nim project with Travis CI, you can run the following
command:

```
make travis-setup
```

Then, you just need to check in the `.travis.yml` file:

```
git add .travis.yml
git commit
```

