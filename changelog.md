# Changelog

## CV 31: Invert/fix ordering for responders
- iterate v.s. pairs should be faster and have a predictable ordering
- tasking the `SearchDownResponderTree` with the array invert turns out to be save work when reusing, and be a little more predictable.

## CV 30 Claim un-handled events within the bounds of `PrimaryFrame`
Leaving unhandled events unclaimed made for a poor interaction experience, when the cursor was clearly over the element.
All base responders now return `true` by default, and events that fail to find a child now trigger for the initial responder they were provided.

## CV 29 Floating Menus
Adds `Menu`, `MenuAnchor`, `RightClickMenuAnchor`, `MultiOptionBox`, `CelledVerticalStack`, and `Cell`. 
See in-code documentation for more details.

## CV 28: `KeyPress`, `KeyRelease` and `TextInput` callin updates
- Rename `char` to `utf8char` in `TextInput`
- Rename `unicode` to `utf32char` in `KeyPress` and `KeyRelease`
- Add `scanCode` and `actionList` arguments in `KeyPress` and `KeyRelease`

## CV 27: Debug improvements
- added `Internal.debugMode.noRasterizer` to specifically disable rasterizers
- Disabled `LogDrawCall` default print spam; instead, we'll rely on external debugging tools overriding this call.
- Rename `component._debugIdentifier` to `component._debugTypeIdentifier`
- Add `component._debugUniqueIdentifier`, which will be a unique integer identifying the component.
- Add `Internal.DebugInfo`, returned by `widget:DebugInfo()` that allows components to report debug information. Please only do so when debug mode is enabled.
- Default to all debug modes off. PLEASE DO NOT COMMIT ANY CHANGES THAT SET ANY DEBUG MODES TRUE, AS THEY SIGNIFICANTLY IMPACT PERFORMANCE.

## CV 26: Improve background rasterizing for `framework:MarginAroundRect`
Now auto-invalidates on resize, move, and correctly invalidates on viewportDidChange.

## CV 25: Add scaling support for `framework:Stroke`
Uses `framework:Dimension` for `stroke.width`

## CV 24: Expose elements & element drawing to aid profiling
Call `framework:GetElement(key)` and `element:Draw()` to get an element and draw it, respectively.

## CV 23: Correctly handle space-grabbing components: HungryStacks
Removed the trickery in `HorizontalStack` & `VerticalStack`: Hungry Stacks allow positioning of predictably-sized views before and after a component of unbounded size, and layout the unbounded component last, making sure it always knows exactly how much space it's got.

## CV 22: File reorg + nice-to-haves
Versioning is now more thorough: you can drag-and-drop multiple frameworks in beside each other and have them (mostly) work. They won't be able to steal focus from each other, for example, but it's a start. Ideally you won't have to constantly bump the versions on all the widgets, but I haven't figured out something to resolve that just yet.

(Almost) every component is now in its own file, to make navigating & adding new stuff a bunch easier.

Various un-committed tweaks (mostly commented/unused stuff) crept in here, and will have to be cleaned up. Behaviour should not have changed, other than specific changes to make such a reorg possible.

A framework-local environment - `framework.Internal` is provided during initialisation. Cache this (`local Internal = Internal` if a component needs to access this table throughout its use.) This allows inter-component communication of values, or communication of internal values to the widget file.
Config data is saved/stored to/from `framework.Internal.ConfigData`. I'd highly recommend each component store their data under in a table keyed into `ConfigData` with their component name - e.g. `framework.Internal.ConfigData.MovableFrame`.

Framework-external dependencies are provided during initialisation as `framework.Include`. Again, anything needed from this table throughout the component's use must be cached.

Various constants that were used in various places are now stored directly in the framework - e.g. `framework.color`, `framework.stroke`, `framework.dimension`. 

Debug:
- All debug functions are now available externally. 
- Debug mode is now enabled by calling `Internal.SetDebugMode(general, draw)` directly after framework initialisation. This includes a new and improved identifier system that automatically adds a debugIdentifier with a table's type, and also automatically adds reporting for draw and layout calls. 

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
