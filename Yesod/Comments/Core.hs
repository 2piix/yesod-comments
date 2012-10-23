{-# LANGUAGE QuasiQuotes       #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE FlexibleContexts  #-}
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

    -- we'll export these for now to ease the refactor
    , getComment
    , storeComment
    , updateComment
    , deleteComment
    , loadComments
    ) where

import Yesod
import Yesod.Auth
import Yesod.Markdown

import Data.Text  (Text)
import Data.Time  (UTCTime)

type ThreadId  = Text
type CommentId = Int

data Comment = Comment
    { threadId  :: ThreadId
    , commentId :: CommentId
    , timeStamp :: UTCTime
    , ipAddress :: Text
    , userName  :: Text
    , userEmail :: Text
    , content   :: Markdown
    , isAuth    :: Bool -- ^ compatability field
    }

instance Eq Comment where
    a == b = (threadId a == threadId b) && (commentId a == commentId b)

data UserDetails = UserDetails
    { textUserName :: Text -- ^ recommended: @toPathPiece userId@
    , friendlyName :: Text
    , emailAddress :: Text
    } deriving Eq

data CommentStorage s m = CommentStorage
    { csGet    :: ThreadId -> CommentId -> GHandler s m (Maybe Comment)
    , csStore  :: Comment -> GHandler s m ()
    , csUpdate :: Comment -> Comment -> GHandler s m ()
    , csDelete :: Comment -> GHandler s m ()
    , csLoad   :: Maybe ThreadId -> GHandler s m [Comment]
    }

getComment :: YesodComments m => ThreadId -> CommentId -> GHandler s m (Maybe Comment)
getComment = csGet commentStorage

storeComment :: YesodComments m => Comment -> GHandler s m ()
storeComment = csStore commentStorage

updateComment :: YesodComments m => Comment -> Comment -> GHandler s m ()
updateComment = csUpdate commentStorage

deleteComment :: YesodComments m => Comment -> GHandler s m ()
deleteComment = csDelete commentStorage

loadComments :: YesodComments m => Maybe ThreadId -> GHandler s m [Comment]
loadComments = csLoad commentStorage

class YesodAuth m => YesodComments m where
    -- | How to store and load comments from persistent storage.
    commentStorage :: CommentStorage s m

    -- | If @Nothing@ is returned, the user cannot add a comment. this can
    --   be used to blacklist users. Note that comments left by them will
    --   still appear until manually deleted.
    userDetails :: AuthId m -> GHandler s m (Maybe UserDetails)

    -- | A thread's route for linking back from the admin subsite. If
    --   @Nothing@, the links will not be present.
    threadRoute :: Maybe (ThreadId -> Route m)
    threadRoute = Nothing

    -- | A route to the admin subsite's EditCommentR action. If @Nothing@,
    --   the link will not be shown.
    editRoute :: Maybe (ThreadId -> CommentId -> Route m)
    editRoute = Nothing

    -- | A route to the admin subsite's DeleteCommentR action. If
    --   @Nothing@, the link will not be shown.
    deleteRoute :: Maybe (ThreadId -> CommentId -> Route m)
    deleteRoute = Nothing
