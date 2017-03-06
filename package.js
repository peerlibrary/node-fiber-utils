Package.describe({
  name: 'peerlibrary:fiber-utils',
  summary: "Various fiber utilities",
  version: '0.8.2',
  git: 'https://github.com/peerlibrary/meteor-fiber-utils.git'
});

Package.onUse(function (api) {
  api.versionsFrom('1.4.2');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'modules'
  ]);

  api.export('FiberUtils');

  api.mainModule('src/meteor-client.coffee', 'client');
  api.mainModule('src/meteor-server.coffee', 'server');
});

Package.onTest(function (api) {
  api.versionsFrom('1.4.2');

  // Core dependencies.
  api.use([
    'underscore',
    'coffeescript'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.2.26'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:fiber-utils'
  ]);

  api.addFiles([
    'tests/tests.coffee'
  ]);
});
