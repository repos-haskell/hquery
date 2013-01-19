module Hquery.Selector where

import Data.Text
import Text.Parsec hiding (many, optional, (<|>))
import Text.Parsec.String
import Text.Parsec.Token
import Text.Parsec.Language

import Control.Applicative

data AttrMod = Remove | Append | Set deriving (Show, Eq)

data AttrSel =
  AttrSel Text AttrMod |
  CData
  deriving (Show, Eq)

data CssSel =
  Id Text |
  Name Text |
  Class Text |
  Attr Text Text |  -- [first=second], special cases for name, id?
  Elem Text |
  Star
  deriving (Show, Eq)

def = emptyDef{ identStart = letter
              , identLetter = alphaNum
              }

TokenParser{ identifier = m_identifier
           , reservedOp = rop
           } = makeTokenParser def

idp :: Parser Text
idp = pack <$> m_identifier

attrModParser :: Parser AttrMod
attrModParser = option Set $
      (Append <$ rop "+")
  <|> (Remove <$ rop "!")

attrSelParser :: Parser (Maybe AttrSel)
attrSelParser = optionMaybe selParser
  where
    selParser :: Parser AttrSel
    selParser =
          AttrSel <$> (rop "[" *> idp) <*> attrModParser <* rop "]"
      <|> CData <$ rop "*"

cssSelParser :: Parser CssSel
cssSelParser = Class <$> (rop "." *> idp)
           <|> Id <$> (rop "#" *> idp)
           <|> Attr <$> (rop "[" *> idp) <*> (rop "=" *> idp <* rop "]")
           <|> Star <$ rop "*"
           <|> Elem <$> idp

commandParser :: Parser (CssSel, Maybe AttrSel)
commandParser = (,) <$> (cssSelParser <* spaces) <*> attrSelParser
