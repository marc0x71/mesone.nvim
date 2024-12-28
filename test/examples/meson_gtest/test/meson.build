test_src = ['unittest.cc']

mytest = executable(
  'unittest', 
  test_src, 
  dependencies: [gtest_dep, gmock_dep],
  install: false) 

test('mytest', mytest, protocol : 'gtest')

