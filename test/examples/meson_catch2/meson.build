project(
  'catch2_integration', 
  'cpp', 
  version: '0.1.0', 
  license: 'MIT')

catch2_dep = dependency('catch2-with-main',
  main: true, disabler: true, required: true,
  default_options: ['tests=false'])

subdir('test')
