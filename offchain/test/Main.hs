module Main where

import Test.Hspec

main :: IO ()
main = hspec $ do
  describe "cardano-bbs" $ do
    it "placeholder" $ do
      True `shouldBe` True
