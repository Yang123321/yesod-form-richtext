module Yesod.Form.Summernote
    ( YesodSummernote (..)
    , snHtmlField
    , snHtmlFieldCustomized
    ) where

-- | Provide the user with the Summernote rich text editor.
--
-- /Note: current implementaion supposes that you set identifiers to editor
-- fields, that is you should provide 'FieldSettings' with 'fsId' set to
-- @Just@-value./
--
-- /Editor fields have hidden textareas with specified identifiers which are
-- updated automatically when editor content changes./
--
-- @
-- summerForm :: Form HtmlComment
-- summerForm = renderBootstrap3 BootstrapBasicForm $ HtmlComment
--   <$> areq (snHtmlFieldCustomized "{toolbar:false}") stitle Nothing
--   <*> areq snHtmlField sbody Nothing
--   where
--     stitle = FieldSettings
--       { fsLabel = "HTML Comment Title"
--       , fsId = Just "html-comment-title"
--       , fsTooltip = Nothing
--       , fsName = Nothing
--       , fsAttrs = [] }
--     sbody = FieldSettings
--       { fsLabel = "HTML Comment Body"
--       , fsId = Just "html-comment-body"
--       , fsTooltip = Nothing
--       , fsName = Nothing
--       , fsAttrs = [] }
-- @


import           Control.Monad                   (when)
import           Data.Maybe                      (listToMaybe)
import           Data.Text                       (Text, pack)
import           Text.Blaze.Html.Renderer.String (renderHtml)
import           Text.Hamlet                     (shamlet)
import           Text.HTML.SanitizeXSS           (sanitizeBalance)
import           Text.Julius                     (julius, rawJS)
import           Yesod.Core
import           Yesod.Form

class Yesod a => YesodSummernote a where
    -- | Bootstrap 3 CSS location.
    urlBootstrapCss :: a -> Either (Route a) Text
    urlBootstrapCss _ =
        Right "http://netdna.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.css"
    -- | Bootstrap 3 library location.
    urlBootstrapScript :: a -> Either (Route a) Text
    urlBootstrapScript _ =
        Right "http://netdna.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.js"
    -- | JQuery library location.
    urlJQueryScript :: a -> Either (Route a) Text
    urlJQueryScript _ =
        Right "http://cdnjs.cloudflare.com/ajax/libs/jquery/2.1.4/jquery.js"
    -- | Summernote Editor CSS location.
    urlSummernoteCss :: a -> Either (Route a) Text
    urlSummernoteCss _ = Right
        "http://cdnjs.cloudflare.com/ajax/libs/summernote/0.8.0/summernote.css"
    -- | Summernote Editor library location.
    urlSummernoteScript :: a -> Either (Route a) Text
    urlSummernoteScript _ = Right
        "http://cdnjs.cloudflare.com/ajax/libs/summernote/0.8.0/summernote.js"
    -- | Should required libraries and scripts be added in DOM tree?  This
    -- property required to control script loading.  In case if you load JQuery,
    -- Bootstrap, and Summernote libraries and CSS in <head> it is not necessary
    -- to load them second time, moreover this could bring some issues, for
    -- example if JQuery is loaded second time it could brake AJAX configuration
    -- from 'defaultCsrfMiddleware'.  Setting this to 'True' could be useful in
    -- case you need single instance of editor on some pages only.
    summernoteLoadLibrariesAndCss :: a -> Bool
    summernoteLoadLibrariesAndCss _ = False

-- | Customizable Summernote editor field.
--
-- @cfg@ argument should be a JSON string object, it will be passed to
-- @summernote()@ function as argument.
--
-- @
-- snHtmlFieldCustomized "{ height: 150, codemirror: { theme:'monokai' } }"
-- @
snHtmlFieldCustomized :: YesodSummernote site
                      => String -> Field (HandlerT site IO) Html
snHtmlFieldCustomized cfg = Field
    { fieldParse =
        \e _ -> return $
            Right . fmap (preEscapedToMarkup . sanitizeBalance) . listToMaybe $ e
    , fieldView = \theId name attrs val _isReq -> do
        toWidget [shamlet|
$newline never
<textarea id="#{theId}" *{attrs} name="#{name}" .html>#{showVal val}
|]
        master <- getYesod
        (when (summernoteLoadLibrariesAndCss master) $ do
            addScript'     urlJQueryScript
            addStylesheet' urlBootstrapCss
            addScript'     urlBootstrapScript
            addStylesheet' urlSummernoteCss
            addScript'     urlSummernoteScript)
        toWidget $ [julius|
$(document).ready(function(){
  var input = document.getElementById("#{rawJS theId}");
  $(input).summernote(#{rawJS cfg}).on('summernote.change',function(){
    $(input).text($(input).summernote('code'));
  });
});|]
    , fieldEnctype = UrlEncoded
    }
  where
    showVal = either id (pack . renderHtml)

-- | Summernote editor field with default settings.
snHtmlField :: YesodSummernote site => Field (HandlerT site IO) Html
snHtmlField = snHtmlFieldCustomized ""


addScript' :: (MonadWidget m, HandlerSite m ~ site)
           => (site -> Either (Route site) Text)
           -> m ()
addScript' f = do
    y <- getYesod
    addScriptEither $ f y

addStylesheet' :: (MonadWidget m, HandlerSite m ~ site)
               => (site -> Either (Route site) Text)
               -> m ()
addStylesheet' f = do
    y <- getYesod
    addStylesheetEither $ f y
