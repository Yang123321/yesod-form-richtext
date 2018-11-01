# Richtext WYSIWYG Editors for Yesod Forms #
[![Build Status](https://travis-ci.org/geraldus/yesod-form-richtext.svg?branch=master)](https://travis-ci.org/geraldus/yesod-form-richtext)

Currently provides following editors support:
+ [Summernote](http://summernote.org/)

and that's all for now! :D

Contributions and feedback are welcome!

Example usage:

```hs
import Yesod.Form.Summernote

summerForm :: Form HtmlComment
summerForm = renderBootstrap3 BootstrapBasicForm $ HtmlComment
  <$> areq (snHtmlFieldCustomized "{toolbar:false}") "Title" Nothing
  <*> areq snHtmlField "Comment" Nothing
```

add support lts-12.14
