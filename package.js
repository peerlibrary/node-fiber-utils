Package.describe({
  name: 'peerlibrary:fiber-utils',
  summary: "Various fiber utilities",
  version: '0.10.0',
  git: 'https://github.com/peerlibrary/node-fiber-utils.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.8.1');

  // Core dependencies.
  api.use([
    'coffeescript@2.4.1',
    'ecmascript',
    'underscore'
  ]);

  api.export('FiberUtils');

  api.mainModule('src/meteor-client.coffee', 'client');
  api.mainModule('src/meteor-server.coffee', 'server');
});

Package.onTest(function (api) {
  api.versionsFrom('METEOR@1.8.1');

  // Core dependencies.
  api.use([
    'coffeescript@2.4.1',
    'ecmascript',
    'underscore'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:classy-test@0.4.0'
  ]);

  // Internal dependencies.
  api.use([
    'peerlibrary:fiber-utils'
  ]);

  api.addFiles([
    'tests/tests.coffee'
  ]);
});
