var gulp = require('gulp');
var gutil = require('gulp-util');
var coffee = require('gulp-coffee');
var pathlib = require('path');
var header = require('gulp-header');
var spawn = require('child_process').spawn;
var paths = {
  coffee: ['./src/**/*.coffee', '!./src/bin/*.coffee'],
  coffeebin: './src/bin/*.coffee',
  sources: ['./src/**/*.sh', './src/**/*.js', './src/**/*.json'],
  jsbin: ['./dist/bin/*.js']
};
gulp.task('clean', function(cb) {
  ch = spawn('rm', ['-rf', pathlib.join(__dirname, 'dist')]);
  ch.on('error', cb);
  ch.on('close', cb);
});
gulp.task('compile', function() {
  gulp.src(paths.coffee)
    .pipe(coffee({bare: true}).on('error', gutil.log))
    .pipe(gulp.dest('./dist'));

  gulp.src(paths.coffeebin)
    .pipe(coffee({bare: true})).on('error', gutil.log)
    .pipe(header('#!/usr/bin/env node\n'))
    .pipe(gulp.dest('./dist/bin'))
});
gulp.task('copy', function() {
  gulp.src(paths.sources)
    .pipe(gulp.dest('./dist'));
});
gulp.task('watch', function() {
  gulp.watch(paths.coffee, ['compile', 'copy']);
});
gulp.task('build', ['clean', 'compile', 'copy']);
gulp.task('default', ['build', 'watch']);


