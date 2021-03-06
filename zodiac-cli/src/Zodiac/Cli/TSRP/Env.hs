{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}

module Zodiac.Cli.TSRP.Env(
    tsrpParamsFromEnv
  ) where

import           Control.Monad.IO.Class (liftIO)

import           Data.ByteString (ByteString)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T

import           P

import           System.Environment (lookupEnv)
import           System.IO (IO)

import           X.Control.Monad.Trans.Either (EitherT, left)

import           Zodiac.Raw
import           Zodiac.Cli.TSRP.Data
import           Zodiac.Cli.TSRP.Error

tsrpParamsFromEnv :: EitherT TSRPError IO TSRPParams
tsrpParamsFromEnv = do
  sk <- getEnvParam "TSRP_SECRET_KEY" >>=
          (parseParam "symmetric key" parseTSRPKey)
  kid <- getEnvParam "TSRP_KEY_ID" >>=
          (parseParam "key ID" parseKeyId)
  pure $ TSRPParams sk kid

parseParam :: Text -> (ByteString -> Maybe' a) -> Text -> EitherT TSRPError IO a
parseParam var f t =
  maybe' (left . TSRPParamError $ InvalidParam var t) pure $ (f . T.encodeUtf8) t

getEnvParam :: Text -> EitherT TSRPError IO Text
getEnvParam var =
  liftIO (lookupEnv (T.unpack var)) >>= \case
    Nothing -> left . TSRPParamError $ MissingRequiredParam var
    Just val -> pure $ T.pack val
