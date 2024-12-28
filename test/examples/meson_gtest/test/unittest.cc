#include "gmock/gmock.h"
#include "gtest/gtest.h"

TEST(FooTest, Simple) { EXPECT_EQ(3, 3); }

TEST(FooTest, Skipped) {
  GTEST_SKIP() << "Skipping single test";
  EXPECT_EQ(3, 3);
}

TEST(FooTest, Fault) { EXPECT_EQ(3, 3); }
