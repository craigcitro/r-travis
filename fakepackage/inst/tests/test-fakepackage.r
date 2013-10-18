context("fake")

test_that("returns 3", {
  expect_equal(3, three())
})

test_that("is_three recognizes 3", {
  expect_that(is_three(3), is_true())
  expect_that(is_three(5), not(is_true()))
  expect_that(is_three(5), is_false())
})
