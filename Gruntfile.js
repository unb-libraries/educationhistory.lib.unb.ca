var pkgJson = require('./package.json');
module.exports = function (grunt) {
  grunt.initConfig({
    clean: {
      composer: ['vendor', 'composer.lock'],
      githooks: ['.git/hooks/*.sample'],
      node: ['node_modules', 'npm-debug.log'],
      tmp_transfer: ['tmp-config', 'tmp-db', 'tmp-files']
    },
    shell: {
      behat_tests: {
        command: 'docker exec ' + pkgJson.config.siteuri  + ' /scripts/runTests.sh'
      },
      copygithooks: {
        command: 'cp package-conf/git-hooks/* .git/hooks/'
      },
      composerinstall: {
        command: './node_modules/.bin/composer install'
      },
      disable_dev_mode: {
        command: 'docker exec ' + pkgJson.config.siteuri  + ' sh -c \'drupal --root=/app/html site:mode prod\''
      },
      enable_dev_mode: {
        command: 'docker exec ' + pkgJson.config.siteuri  + ' sh -c \'drupal --root=/app/html site:mode dev\''
      },
      instance_start_over: {
        command: './scripts/local/instance_start_over.sh ' + pkgJson.config.upstream_image
      },
      instance_destroy: {
        command: './scripts/local/instance_destroy.sh'
      },
      instance_start: {
        command: './scripts/local/instance_start.sh ' + pkgJson.config.upstream_image
      },
      instance_stop: {
        command: './scripts/local/instance_stop.sh'
      },
      gitclean: {
        command: 'git clean -fdx'
      },
      gitpullcurrent: {
        command: './scripts/local/git_pull_current_branch.sh'
      },
      node_install: {
        command: 'npm install'
      },
      remote_dev_sync: {
        command: './scripts/local/sync_from_remote.sh ' + pkgJson.config.siteuri  + ' ' + pkgJson.config.devhost
      },
      tail_logs: {
        command: 'docker-compose logs -f'
      },
      uli: {
        command: 'docker exec ' + pkgJson.config.siteuri  + ' sh -c \'drush --root=/app/html uli | sed -e "s|http://default|$DEV_WEB_URI|g"\''
      },
      validatephp: {
        command: './.git/hooks/pre-commit || true'
      },
      write_config: {
        command: 'docker exec ' + pkgJson.config.siteuri  + ' /scripts/configExport.sh'
      },
      options: {
        execOptions: {
          maxBuffer: Infinity
        }
      }
    }
  });

  grunt.loadNpmTasks('grunt-contrib-clean');
  grunt.loadNpmTasks('grunt-shell');

  grunt.registerTask('behat-tests', ['shell:behat_tests']);
  grunt.registerTask('composerinstall', ['clean:githooks', 'shell:composerinstall']);
  grunt.registerTask('default', ['clean']);
  grunt.registerTask('disable-dev-mode', ['shell:disable_dev_mode']);
  grunt.registerTask('enable-dev-mode', ['shell:enable_dev_mode']);
  grunt.registerTask('clean:all', ['clean:composer', 'clean:githooks', 'clean:node', 'clean:tmp_transfer', 'shell:gitclean']);
  grunt.registerTask('githooks', ['clean:githooks', 'shell:copygithooks']);
  grunt.registerTask('instance-destroy', ['shell:instance_destroy']);
  grunt.registerTask('instance-start-over', ['shell:instance_stop', 'shell:instance_destroy', 'shell:instance_start']);
  grunt.registerTask('instance-start', ['shell:instance_start']);
  grunt.registerTask('instance-stop', ['shell:instance_stop']);
  grunt.registerTask('remote-dev-sync', ['shell:remote_dev_sync']);
  grunt.registerTask('repo-start-over', ['shell:instance_stop', 'shell:instance_destroy', 'clean:all', 'shell:gitpullcurrent', 'shell:node_install', 'setup']);
  grunt.registerTask('setup', ['validationsetup']);
  grunt.registerTask('tail-logs', ['shell:tail_logs']);
  grunt.registerTask('write-config', ['shell:write_config']);
  grunt.registerTask('uli', ['shell:uli']);
  grunt.registerTask('validate-php', ['shell:validatephp']);
  grunt.registerTask('validationsetup', ['githooks', 'composerinstall']);
};
