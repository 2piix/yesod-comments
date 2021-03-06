{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts  #-}
{-# LANGUAGE ConstraintKinds   #-}
{-# LANGUAGE TypeFamilies      #-}
-------------------------------------------------------------------------------
-- |
-- Module      :  Yesod.Comments.Core
-- Copyright   :  (c) Patrick Brisbin 2010
-- License     :  as-is
--
-- Maintainer  :  pbrisbin@gmail.com
-- Stability   :  unstable
-- Portability :  unportable
--
-------------------------------------------------------------------------------
module Yesod.Comments.Core
    ( YesodComments(..)
    , CommentId
    , ThreadId
    , Comment(..)
    , UserDetails(..)
    , CommentStorage(..)
    ) where

import Yesod
import Yesod.Auth
import Yesod.MathJax

import Data.Text  (Text)
import Data.Time  (UTCTime)

type ThreadId  = Text
type CommentId = Int

-- | The core data type, a Comment
data Comment = Comment
    { commentId  :: CommentId
    , cThreadId  :: ThreadId
    , cTimeStamp :: UTCTime
    , cIpAddress :: Text
    , cUserName  :: Text
    , cUserEmail :: Text
    , cContent   :: MathJax
    , cIsAuth    :: Bool -- ^ compatability field, always true
    }

instance Eq Comment where
    a == b = (cThreadId a == cThreadId b) && (commentId a == commentId b)

-- | Information about the User needed to store comments.
data UserDetails = UserDetails
    { textUserId   :: Text -- ^ Text version of a user id, @toPathPiece
                           --   userId@ is recommended. Comments are stored
                           --   using this value so users can freely change
                           --   names without losing comments.
    , friendlyName :: Text -- ^ The name that's actually displayed
    , emailAddress :: Text -- ^ Not shown but stored
    } deriving Eq

-- | How to save and restore comments from persistent storage. All
--   necessary actions are accomplished through these 5 functions.
--   Currently, only @persistStorage@ is available.
data CommentStorage s m = CommentStorage
    { csGet    :: ThreadId -> CommentId -> HandlerT m IO (Maybe Comment)
    , csStore  :: Comment -> HandlerT m IO ()
    , csUpdate :: Comment -> Comment -> HandlerT m IO ()
    , csDelete :: Comment -> HandlerT m IO ()

    -- | Pass @Nothing@ to get all comments site-wide.
    , csLoad   :: Maybe ThreadId -> HandlerT m IO [Comment]
    }

class YesodAuthPersist m => YesodComments m where
    -- | How to store and load comments from persistent storage.
    commentStorage :: CommentStorage s m

    -- | If @Nothing@ is returned, the user cannot add a comment. This can
    --   be used to blacklist users. Note that comments left by them will
    --   still appear until manually deleted.
    userDetails :: AuthId m -> HandlerT m IO (Maybe UserDetails)

    -- | A thread's route. Currently, only used for linking back from the
    --   admin subsite.
    threadRoute :: ThreadId -> Route m

    -- | A route to the admin subsite's EditCommentR action. If @Nothing@,
    --   the Edit link will not be shown.
    editRoute :: Maybe (ThreadId -> CommentId -> Route m)
    editRoute = Nothing

    -- | A route to the admin subsite's DeleteCommentR action. If
    --   @Nothing@, the Delete link will not be shown.
    deleteRoute :: Maybe (ThreadId -> CommentId -> Route m)
    deleteRoute = Nothing
