# Changelog

## CV 21: Wrapping Text

Added `framework:WrappingText`! `WrappingText` stores a `rawString` and displays a `displayString`, with an interface to convert character between them. Text colouring is also supported: override `WrappingText:ColoredString(string)` to annotate the raw string (e.g. for code syntax highlighting). Support for return-based newlines was added (`wrappingText:editReturn()`) and indices for delete + backspace were fixed.

`framework:TextEntry` now wraps a `WrappingText`. Provide `1` as a value for `maxLines` to prevent wrapping. Click-and-drag selection is now supported, and block selection is now shown while deselected.

Text is now a custom `WrappingText` that drops the `constantWidth`, `constantHeight` and `watch` options. `constantHeight` is replaced with `maxLines`, and width restrictions will have to be provided by a wrapping container. `Text:GetString()` is still available, simply returning `WrappingText:GetRawString()`. (NB `watch` appears to already have been disabled.)

funcs.lua:
Added `string:lines()`, `string:inserting(newString, index)`, `string:unEscaped(showNewlines)`.

`unEscaped` is primarily for debug purposes.

...

## CV 9

View elements no longer take a number for constant dimensions; instead, they accept a function which will return a value. Further internal optimisations to be made, and possibly allowance for providing element-specific scalings. Currently, scaling is provided based on a single constant, and relative to 1080p.
Also tweaked changelog formatting because why not :)

## CV 8

Added `framework:Blending`; wraps decorations (which execute GL calls) in a gl.Blending call, resetting to default after.

## CV 7

Improved mouse over handling to provide calls for enter & leave

## CV 6

Added TextGroups
Rasterizer & PrimaryFrame body restricted to `element:SetBody(newBody)`