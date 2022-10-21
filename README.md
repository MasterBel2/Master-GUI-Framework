# Master-GUI-Framework
A GUI framework for the Spring Engine.

This readme is outdated, but still vaguely correct.

## Overview:

This framework provides a group of basic UI components that can be combined to build a complex UI. An interface element simply has to implement a `Layout()` and `Draw(x, y)` function, and have an entry for `.width` and `.height` in the table. For a basic example, see `framework:Rect()`.

Components only know their own size, so the parent component must advise their position in `Draw(x, y)`. A basic example is as follows:

```lua
function component:Draw(x, y)
    component.body:Draw(x + bodyXOffset, y + bodyYOffset)
end
```

## Performance

To avoid constant re-drawing of components you know will not change every frame, wrap them in a Rasterizer. The Rasterizer will compile a draw list. You must tell it when it needs to redraw by setting:

```lua
rasterizer.invalidated = true
```

Note that the Rasterizer does not literally "rasterize" – it only compiles and calls a draw list. I just couldn't come up with a better name. :)

## Framework versioning

To allow multiple versions of the framework to work alongside each other, frameworks are flagged by a compatibility version. Including is as simple as follows:

```lua
local MasterFramework
local requiredFrameworkVersion = 1

widget:Initialize()
    MasterFramework = WG.MasterFramework[requiredFrameworkVersion]
    if not MasterFramework then
        Spring.Echo("[WidgetName] Error: MasterFramework " .. requiredFrameworkVersion .. " not found! Removing self.")
        widgetHandler:RemoveWidget(self)
        return
    end
end
```

`WG.MasterFramework` is guarantee to be available only from when `widget:Initialize()` is called, and not before.

## Examples

- [Master MiniMap](https://github.com/MasterBel2/Master-MiniMap)

## Notes

For support, MasterBel2 can be contacted at untakenprefix🍎gmail.com
