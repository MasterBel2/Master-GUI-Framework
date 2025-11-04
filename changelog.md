# Changelog

## WIP: Coordinate Update, Optimisation & Simplification; Text Highlight API

`DrawingGroup` resets coordinates to avoid unnecessarily calling `Position` when portions of the UI move uniformly. To support this:
- `DrawingGroup` provides `drawingGroup:AbsolutePosition()` to move local coordinates to a global context. E.g., comparing bounds v.s. interaction in `Responder`.
 - (Internal detail: To performantly propagate changes to a `DrawingGroup`'s position, `DrawingGroup` will call `drawingGroup:SetParentGroupPosition(x, y)` on its children, to inform of the new result that would be returned by `drawingGroup:AbsolutePosition()`)
 - (Internal detail: `GeometryTarget`s will now also register with their parent `DrawingGroup` (`drawingGroup.childGeometryTargets`) to receive `geometryTarget:SetParentGroupPosition(x, y)`, again as a performance optimisation)
- `GeometryTarget` no longer provides `CachedPosition`. Instead, this functionality is split out into the following API:
 - `geometryTarget:CachedPositionRemainingInLocalContext()`
 - `geometryTarget:CachedPositionTranslatedToGlobalContext()`
 - `geometryTarget:CachedPositionTranslatedToContext(callerDrawingGroup)`
 - `geometryTarget:ContainsAbsolutePoint(x, y)`
 - `geometryTarget:ContainsPoint(x, y, callerDrawingGroup)`
(see `Layout/GeometryTarget.lua` for further details.)
- `_debug_mouseOver` is now a separate event listed in `framework.events`.

Other architectural changes:
- `Responder`, `PrimaryFrame`, `WrappingText`, and `Background` now inherit from `GeometryTarget`. See `GeometryTarget` for expanded interface.
- `Tooltip` now inherits from `Responder`, and `tooltip` is now listed in `framework.events`.
- `Component` now has a single associated drawing group. Let me stress, then the importance of making sure reusable tools inherit from `Drawer`, not `Component`! (`Component` must necessarily be contained in one single drawing group for reasons I can't remember. Maybe convenience, then.)
- `DrawingGroup` advertises `CachedSize` now to go with `AbsolutePosition` - but do not be fooled, this is NOT a full implementation of `GeometryTarget`.
- Remove `framework.viewportDidChange`. It was unused, and other, more robust methods can be used to respond to updates (e.g. `AutoScalingDimension`).
- `drawingGroup.needsRedraw` is not set in `drawingGroup:UpdateLayout(calledByParent)`, since it's already set in `drawingGroup:UpdatePosition()`
- (Internal detail: `drawingGroup.groupsNeedingLayout` and `drawingGroup.groupsNeedingPosition` will not remove any groups until directly before `drawingGroup:UpdatePosition()` is called, to allow `drawingGroup:Position(x, y)` to trigger `drawingGroup:UpdatePosition()` if necessary.)

Text Highlight API:
- `WrappingText` now handles the selection highlight drawing for `TextEntry` with a public API! See documentation in `WrappingText.lua`:
  - `wrappingText:HighlightRange(color, startIndex, endIndex, reuseLast)`
  - `wrappingText:UpdateHighlight(id, color, startIndex, endIndex, reuseLast)`
  - `wrappingText:RemoveHighlight(id)`
- `TextGroup` now calls `wrappingText:DrawText(glFont)` rather than `wrappingText:Draw(glFont)` to avoid collision when `DrawingGroup` calls `wrappingText:Draw()`

Visual changes:
- Squared-off corners at the edge of the screen have been disabled, due to drawing no longer knowing whether it's actually at the edge of the screen.
- Round fonts to the nearest pixel size (to prevent blurry text).

Debug changes:
- Remove redundant `Internal._debug_currentElementKey` in favour of `Internal.activeElement.key`.
- Add argument & return value validation for `Position` & `Layout`.
- Include stacktrace for framework error messages (debug mode must be enabled, because this comes with a significant performance cost).
- Add some tests matched to some solved `dimension:Update(...)` bugs.
- Inject some profiling only when debug mode is enabled. Other profiling has been removed.
- Some error catching has been made less fine-grained for performance reasons. With stacktraces enabled, this should not tangibly hamper debugging.
- Drawing will terminate completely after an error, rather than completing the other passes in the element's final frame.

Bug fixes:
- Hide `MovableFrame` handle when releasing outside bounds)
- Fix over-cropping for `OffsettedViewport`. (I suspect this happens with height too, but so far I haven't been able to verify. There's chance the error's something else, idk.)

Also includes further non-breaking (hopefully) optimisations and fixes.

## CV 43: Limit unnecessary layout / position / draw passes

Agressive changes have been made to how updates are made to reduce the necessary fequency of calculations:
- `Rasterizer` has been merged into `DrawingGroup`.
- `DrawingGroup` now uses draw lists by default. See documentation for how to disable this, for cases where it harms performance.
- `Position` can now be expected to be called more than once for some `Layout` calls, where sizing hasn't changed but positioning has (e.g. )
- Even if rasterization isn't involved, `Draw` can be called more than once per `Position`/`Layout` call.
- To specifically request an update to any of `Layout`/`Position`/`Draw`, the corresponding property may be set on the relevant `DrawingGroup`. See `Drawer` and `Component` for more detail and example implementations.
- DrawingGroup has a property `drawingGroup.pass` that indicates what stage of UI rendering is being performed. `Dimension`s in particular use this to know which stage to invalidate, as a `Dimension` used in the Layout phase will require all stages to be refreshed, while a `Dimension` used in the draw phase will only require a re-draw.
- Components can indicate they require a re-drawing every frame, to avoid the overhead of an unhelpful draw list. Call `component:EnableContinuousDrawing` (see `Drawing/Decorations/Drawer.lua` for more details.)

To facilitate this:
- Most components that allow specifying a child no longer make their child editable; instead, when you wish to mutate a child view hierarchy, set the parent's initial child to `Box`, which allows its child to be changed (via `Box:SetChild(newChild)`).
- `Rect`, `MarginAroundRect`, and `Cell` no longer draw decorations. Use `Background` instead to attach a background.
  (Note that `Background` doesn't have the rasterizing optimisation that `MarginAroundRect` did; instead, use nested `DrawingGroup`s to separate the re-drawing profile of different parts of the interface hierarchy.) 
- `HorizontalStack`, `VerticalStack`, and `StackInPlace` no longer make their members public; instead, they must be set/get through methods that copy to/from the internal member array.
- Other mutable properties for other component types must be changed through methods, similar to above.
- Some properties are simply no longer mutable.
- `Dimension` now has a base constructor that registers for updates with the drawing group; the previous functionality of the `Dimension` function has moved to `AutoScalingDimension`.
- `OffsettedViewport` is now an overriding extension of `DrawingGroup`.

Changes to `Menu`:
- `MenuAnchor` now provides `menuAnchor:GetMenu()` to allow accessing its menu.
- `Menu` provides `menu:IsMouseOver()` which returns whether the user's cursor is over the menu or one of its submenus.
- `Menu`'s submenu menu items are now a `MenuAnchor` at the top level, rather than a `MarginAroundRect` at the top level. (This probably shouldn't be of practical concern to users of the framework.)

Misc other changes:
- Remove elements with incomplete `PrimaryFrame` geometry, to prevent log spam and allow interaction
- Various bugfixes
- TextEntry & Button store their colours in constants, providing potential to override & set custom styles
- `PrimaryFrame` no longer attempts recovery if `Layout` hasn't been called yet
- `Element`s are removed if no `PrimaryFrame` is present in the view hierarchy
- `HorizontalScrollContainer` and `VerticalScrollContainer` now use the customisable `framework.dimension.scrollMultiplier` to configure their scroll speed. This should provide the same scrolling experience on a 1080p display, and scale better to larger resolutions.

## CV 42: Misc - kill funcs.lua, separate out constants, change WG access
Extensions are now declared in `MasterFramework $VERSION/Utils`, and pre-loaded before the rest of the framework. These are provided the same global environment as the rest of the framework. `string` extensions now all have `_MasterFramework` at the end of their name, while the `table` extension overrides the `Include.table` table for the framework, and provides access to the customised version as `framework.table`. The definition of `Include.clear` has been moved to `Utils/table.lua`, and `table.joinStrings()` has been removed, since it was a slower reimplementation of `table.concat()`

Constants have been moved out of `gui_master_framework.lua` into separate files in the `Constants/` directory. Subfiles are not automatically loaded to allow for dependencies, other than the entry point `Constants/constants.lua`.

The main framework files which would have been loaded in previous versions are now contained in the `Framework/` directory.

The new major directories are loaded in this order: `Utils/`, `Framework/`, then `Constants/`.

Framework access is no longer provided as WG.MasterFramework[compatabilityVersion], instead as WG["MasterFramework " .. compatabilityVersion]. Removing the intermediate table technically simplifies this?

## CV 41: Expose VerticalScrollContainer's viewport as `container.viewport`

## CV 40: TextEntry - Cursor up/down support, fix cursor movement after mouse selection
To make handling selection changes more graceful:
- Added `entry:CurrentCursorIndex()` returns the current primary selection index - i.e. which one should be manipulated on a selection change (based on selectFrom).
- Added `entry:MoveCursor(destinationIndex, isShift)` to handle all keyboard-based selection changes.

All selection handling now uses `entry:MoveCursor()` to ensure that `selectFrom`, `selectionChangedClock`, and `entry.selectionEnd` are correctly updated. This also fixes some bugs with mouse selection where keyboard selection changes would be incorrect directly after a mouse selection.

Adds `entry:editAbove()` and `entry:editBelow()` for moving cursor up/down. Use with ctrl to jump to the next raw (not visual) newline.

TODO: `entry:editAbove()` and `entry:editBelow()` could remember the starting X coordinate, so as to not forget e.g. across a newline.

## CV 39: Fully implement ctrl-based delete/backspace and fix ctrl-move
Simply implements the (ctrl) argument of `textEntry:editDelete(ctrl)`, `textEntry:editBackspace(ctrl)`, `textEntry:editLeft(ctrl)`, `textEntry:editRight(ctrl)`

## CV 38: WrappingText, TextEntry & string:lines Performance Optimisations
- rename `string:lines` to `string:lines_MasterFramework` to disambiguate from BAR's implementation
- by default, don't extract a substring for each parsed line. Call `string:lines_MasterFramework(true)` to return an array of strings containing each extracted line.

WrappingText and TextEntry use this optimised lines function for better performance.

- localize a few functions for speed
- provided arguments for supplying a partial result to `wrappingText:RawIndexToDisplayIndex` to avoid repeated work
- other minor tweak(s)

- Also slightly improves selection box drawing, namely including an indication of whether the newline is selected

## CV 37: TextEntry: support Undo / Redo / Cut / Copy / Paste
Adds the following methods:
- `textEntry:InsertUndoAction(undoAction, redoAction)`: Adds an undo action and an associated redo action to the undo/redo log.
- `textEntry:InsertText(newText)`: Inserts the text at the current index. The insertin is added to the undo/redo log.
- `textEntry:editCopy()`: For a point selection, noop. For a block selection, copies the current selection to clipboard. (Called for a Ctrl+C keypress.)
- `textEntry:editPaste()`: For a point selection, inserts the contents of the pasteboard at the current selection. For a block selection, copies the current selection to clipboard. (Called for a Ctrl+V keypress.) The text addition is added to the undo/redo log.
- `textEntry:editCut()`: For a point selection, noop. For a block selection, copies the current selection to clipboard, and removes it from the textEntry's text. (Called for a Ctrl+C keypress.) The text removal is added to the undo/redo log.
- `textEntry:editUndo()`: Applies any undo action at the current index, and increases the index by one. (Called for a Ctrl+Z keypress.)
- `textEntry:editRedo()`: Applies any redo action at the current index, and decreases the index by one. (Called for a Ctrl+Shift+Z keypress.)

Editing clips the undo/redo log to the current index. Redo indices are offset by undo indices by one, such that a redo cannot be called until an undo has been performed, and once all undos have been performed, the last redo will still be available.

## CV 36: Allow Click-through elements
Specify `true` for `allowInteractionBehind` when calling `framework:InsertElement()` to allow click-through

## CV 35: Better scrolling implementation
API changes:
 - Replace `autowidth` and `autoheight` arguments with `mode`
   `mode` specifies which axes the content can exceed the viewport's dimensions.
   `mode` can be one of the following:
    - `framework.OFFSETTED_VIEWPORT_MODE_HORIZONTAL_VERTICAL`
    - `framework.OFFSETTED_VIEWPORT_MODE_HORIZONTAL`
    - `framework.OFFSETTED_VIEWPORT_MODE_VERTICAL`
   An error with a descriptive message will be provided if an invalid value is provided.

Scrollbars will be provided in dimensions that exceed the viewport's bounds and have been clipped.
`mode` is immutable.

Bugs fixed:
 - Viewport not clipping to its bounds
 - Viewport scrollbars not receiving input when the content in the viewport is interactive

## CV 34: Move Drawing to Groups
- Draw to Position; all drawing components defer drawing to a `framework:DrawingGroup`
- `framework:TextGroup` now calls `text:Draw` instead of `text:DrawForReal`
- Many places that wrapped their children in a `framework:TextGroup` now wrap their children in a `framework:DrawingGroup`, since it also provides a text group

Bugfixes:
- Fixed missing include for `gl_Blending` that broke `framework:Blending`

Misc debug changes:
- Bugfix: No longer attempt to log nil messages
- Displays message in console when debug mode is enabled
- Provide debug information for `framework:ResizableMovableFrame`
- Provide debug information for `framework:MovableFrame`
- Store responder event in `responder._event`

Also updated readme! :)

## CV 33: New component debugging system
Displays component borders on-screen, and shows debug info about the component under mouse.
Call `frameworkInternal.SetDebugMode(?, false, ?)` in the framework's initialiser to enable.

## CV 32: Swap button's margin for a cell
This delegates the padding, which makes it more flexible.

## CV 31: Invert/fix ordering for responders
- iterate v.s. pairs should be faster and have a predictable ordering
- tasking the `SearchDownResponderTree` with the array invert turns out to be save work when reusing, and be a little more predictable.

## CV 30: Claim un-handled events within the bounds of `PrimaryFrame`
Leaving unhandled events unclaimed made for a poor interaction experience, when the cursor was clearly over the element.
All base responders now return `true` by default, and events that fail to find a child now trigger for the initial responder they were provided.

## CV 29: Floating Menus
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
