#include <catch2/catch_test_macros.hpp>
#include <iostream>

TEST_CASE("Simple test 1", "[libfoo]") {
  std::cout << "simple test output\n";
  REQUIRE(2 == 2);
}

TEST_CASE("This test will be skipped", "[libfoo]") {
  std::cout << "failed test output\n";
  std::cerr << "failed test error\n";
  REQUIRE(2 == 2);
  SKIP();
}

TEST_CASE("This test will fail", "[libfoo]") { REQUIRE(2 == 2); }
