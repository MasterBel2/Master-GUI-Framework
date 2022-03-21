# Changelog

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