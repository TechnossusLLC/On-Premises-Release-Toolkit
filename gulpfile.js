var gulp = require('gulp');
var path = require('path');
var del = require('del');
var shell = require('shelljs')
var pkgm = require('./package');
var gutil = require('gulp-util');
var zip = require('gulp-zip');
var minimist = require('minimist');
var os = require('os');
var fs = require('fs');
var semver = require('semver');
var Q = require('q');
var exec = require('child_process').exec;
var tsc = require('gulp-tsc');
var mocha = require('gulp-mocha');
var cp = require('child_process');
var runSequence = require('run-sequence');

var NPM_MIN_VER = '3.0.0';
var MIN_NODE_VER = '4.0.0';

if (semver.lt(process.versions.node, MIN_NODE_VER)) {
    console.error('requires node >= ' + MIN_NODE_VER + '.  installed: ' + process.versions.node);
    process.exit(1);
}

/*
Distinct build, test and Packaging Phases:

Build:
- validate the task.json for each task
- generate task.loc.json file and strings file for each task.  allows for hand off to loc.
- compile .ts --> .js
- "link" in the vso-task-lib declared in package.json into tasks using node handler

Test:
- Run Tests (L0, L1) - see docs/runningtests.md
- copy the mock task-lib to the root of the temp test folder
- Each test:
   - copy task to a temp dir.
   - delete linked copy of task-lib (so it uses the mock one above)
   - run

Package (only on windows):
- zip the tasks.
- if nuget found (windows):
  - create nuget package
  - if server url, publish package - this is for our VSO build 
*/

var mopts = {
    boolean: 'ci',
    string: 'suite',
    default: { ci: false, suite: '**' }
};

function getFolders(dir) {
    return fs.readdirSync(dir)
        .filter(function (file) {
            return fs.statSync(path.join(dir, file)).isDirectory();
        });
}

var options = minimist(process.argv.slice(2), mopts);

var _buildRoot = path.join(__dirname, '_build', 'Tasks');
var _testRoot = path.join(__dirname, '_build', 'Tests');
var _testTemp = path.join(_testRoot, 'Temp');
var _pkgRoot = path.join(__dirname, '_package');
var _oldPkg = path.join(__dirname, 'Package');
var _wkRoot = path.join(__dirname, '_working');

var _tempPath = path.join(__dirname, '_temp');

gulp.task('clean', function (cb) {
    del([_buildRoot, _tempPath, _pkgRoot, _wkRoot, _oldPkg], cb);
});

gulp.task('cleanTests', function (cb) {
    del([_testRoot], cb);
});

gulp.task('compileTests', ['cleanTests'], function (cb) {
    var testsPath = path.join(__dirname, 'Tests', '**/*.ts');
    return gulp.src([testsPath, 'definitions/*.d.ts'])
        .pipe(tsc())
        .pipe(gulp.dest(_testRoot));
});

gulp.task('ps1tests', ['compileTests'], function (cb) {
    return gulp.src(['Tests/**/*.ps1', 'Tests/**/*.json'])
        .pipe(gulp.dest(_testRoot));
});

gulp.task('testLib', ['compileTests'], function (cb) {
    return gulp.src(['Tests/lib/**/*'])
        .pipe(gulp.dest(path.join(_testRoot, 'lib')));
});

gulp.task('testResources', ['testLib', 'ps1tests']);

// compile tasks inline
gulp.task('compileTasks', ['clean'], function (cb) {
    try {
        getLatestTaskLib();
    }
    catch (err) {
        console.log('error:' + err.message);
        cb(new gutil.PluginError('compileTasks', err.message));
        return;
    }


    var tasksPath = path.join(__dirname, 'Tasks', '**/*.ts');
    return gulp.src([tasksPath, 'definitions/*.d.ts'])
        .pipe(tsc())
        .pipe(gulp.dest(path.join(__dirname, 'Tasks')));
});

gulp.task('compile', ['compileTasks', 'compileTests']);

gulp.task('build', ['compileTasks'], function () {
    shell.mkdir('-p', _buildRoot);
    return gulp.src(path.join(__dirname, 'Tasks', '**/task.json'))
        .pipe(pkgm.PackageTask(_buildRoot));
});

gulp.task('copyPowershellCommon', function () {
    var folders = getFolders(_buildRoot);

    var tasks = folders.map(function (folder) {
        return gulp.src(path.join(__dirname, 'Tasks', 'Common', '**/*.ps1'))
            .pipe(gulp.dest(path.join(_buildRoot, folder)));
    });
});

gulp.task('copyMiscFiles', function () {
    return gulp.src([path.join(__dirname, 'Tasks', 'extension-icon.png'), path.join(__dirname, 'Tasks', 'vss-extension.json')])
        .pipe(gulp.dest(_buildRoot));

});

gulp.task('test', ['testResources'], function () {
    process.env['TASK_TEST_TEMP'] = _testTemp;
    shell.rm('-rf', _testTemp);
    shell.mkdir('-p', _testTemp);

    var suitePath = path.join(_testRoot, options.suite + '/_suite.js');

    return gulp.src([suitePath])
        .pipe(mocha({ reporter: 'spec', ui: 'bdd', useColors: !options.ci }));
});

gulp.task('default', function (callback) {
    runSequence('build', 'copyPowershellCommon', 'copyMiscFiles', callback);
});

//-----------------------------------------------------------------------------------------------------------------
// INTERNAL BELOW
//
// This particular task is for internal microsoft publishing as a nuget package for the VSO build to pick-up
// Contributors should not need to run this task
// This task requires windows and direct access to the internal nuget drop
//-----------------------------------------------------------------------------------------------------------------

var getLatestTaskLib = function () {
    gutil.log('Getting latest vso-task-lib');
    shell.mkdir('-p', path.join(_tempPath, 'node_modules'));

    var pkg = {
        "name": "temp",
        "version": "1.0.0",
        "description": "temp to avoid warnings",
        "main": "index.js",
        "dependencies": {},
        "devDependencies": {},
        "repository": "http://norepo/but/nowarning",
        "scripts": {
            "test": "echo \"Error: no test specified\" && exit 1"
        },
        "author": "",
        "license": "MIT"
    };
    fs.writeFileSync(path.join(_tempPath, 'package.json'), JSON.stringify(pkg, null, 2));

    shell.pushd(_tempPath);

    var npmPath = shell.which('npm');
    if (!npmPath) {
        throw new Error('npm not found.  ensure npm 3 or greater is installed');
    }

    var s = cp.execSync('"' + npmPath + '" --version');
    var ver = s.toString().replace(/[\n\r]+/g, '')
    console.log('version: "' + ver + '"');

    if (semver.lt(ver, NPM_MIN_VER)) {
        throw new Error('NPM version must be at least ' + NPM_MIN_VER + '. Found ' + ver);
    }

    var cmdline = '"' + npmPath + '" install vso-task-lib';

    var res = cp.execSync(cmdline);
    gutil.log(res.toString());
    shell.popd();
    if (res.status > 0) {
        throw new Error('npm failed with code of ' + res.status);
    }
}
