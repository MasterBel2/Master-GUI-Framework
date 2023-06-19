# Master-GUI-Framework
A GUI framework for the Spring Engine.

This readme is outdated, but still vaguely correct.

## Installing

Copy/symlink `funcs.lua` and `gui_master_framework_23.lua` to your Spring installation's `LuaUI/Widgets/` folder, and the `MasterFramework 23` folder to your `LuaUI/` folder, forming the path `LuaUI/MasterFramework 23/`.

As a result, your LuaUI directory should look like this:
```
LuaUI/
    MasterFramework 23/
    Widgets/
        funcs.lua
        gui_master_framework_23.lua
        ...
    ...
```

Once installed, make sure you enable `MasterBel2's GUI Framework (23)` in Widget Selector. See [Barebones Example](#Barebones-Example) for how to use MasterFramework in your project.

## Overview:

This framework provides a group of basic UI components that can be combined to build a complex UI. An interface element simply has to implement the `Layout(availableWidth, availableHeight)` and `Draw(x, y)` functions. For a basic example, see `framework:Rect()`.

Components only know their own size, so the parent component must advise their position in `Draw(x, y)`. A basic example is as follows:

```lua
function component:Draw(x, y)
    component.body:Draw(x + bodyXOffset, y + bodyYOffset)
end
```

```lua
function component:Layout(availableWidth, availableHeight)
    -- Do something, e.g. computing the size of the child
    return width, height
end
```

To display a UI element, call `framework:InsertElement()`. At the top level, a UI element must be a component, that either is or contains a `framework:PrimaryFrame()`.

## Scaling

Many components are designed to automatically adapt to screen size changes. Rather than taking constant sizes, some components require a function that will provide a scaled dimension on demand.

The framework provides `framework:Dimension()` which automatically scales a provided constant with the screen size.


## Performance

To avoid constant re-drawing of components you know will not change every frame, wrap them in a Rasterizer (see `framework:Rasterizer()`). The Rasterizer will compile a draw list. You must tell it when it needs to redraw by setting:

```lua
rasterizer.invalidated = true
```

Currently, nested rasterizers have no performance benefit, as draw lists cannot be nested.

Note that the Rasterizer does not literally "rasterize" – it only compiles and calls a draw list. I just couldn't come up with a better name. :)

## Framework versioning

To allow multiple versions of the framework to work alongside each other, frameworks are flagged by a compatibility version. Including is as simple as follows:

```lua
local MasterFramework
local requiredFrameworkVersion = 14

widget:Initialize()
    MasterFramework = WG.MasterFramework[requiredFrameworkVersion]
    if not MasterFramework then
        Spring.Echo("[WidgetName] Error: MasterFramework " .. requiredFrameworkVersion .. " not found! Removing self.")
        widgetHandler:RemoveWidget(self)
        return
    end
end
```

`WG.MasterFramework` is guaranteed to be available only from when the framework's `widget:Initialize()` is called, and not before.

### Barebones Example

Shows "Hello World" In the lower left-hand corner of the screen:

```lua
function widget:GetInfo()
    return {
        name = "MasterFramework Example"
    }
end

local MasterFramework
local requiredFrameworkVersion = 23

local key

function widget:Initialize()
    MasterFramework = WG.MasterFramework[requiredFrameworkVersion]
    if not MasterFramework then
        Spring.Echo("[WidgetName] Error: MasterFramework " .. requiredFrameworkVersion .. " not found! Removing self.")
        widgetHandler:RemoveWidget(self)
        return
    end

    key = MasterFramework:InsertElement(
        MasterFramework:PrimaryFrame(
            MasterFramework:Text("Hello world!")
        ),
        "MasterFramework Example",
        MasterFramework.layerRequest.anywhere()
    )
end

function widget:Shutdown()
    if MasterFramework and key then
        MasterFramework:RemoveElement(key)
    end
end
```

## Other Examples

- [Master Keytracker](https://github.com/MasterBel2/Master-Keytracker) (outdated)
- [Master MiniMap](https://github.com/MasterBel2/Master-MiniMap) (outdated)

## Notes

For support, MasterBel2 can be contacted at untakenprefix🍎gmail.com
