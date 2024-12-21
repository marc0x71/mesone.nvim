project(
  'gtest_integration', 
  'cpp', 
  version: '0.1.0', 
  license: 'MIT')

gtest_dep = dependency('gtest_main', main: true, disabler: true, required: true)
gmock_dep = dependency('gmock', disabler: true, required: true)

subdir('test')
