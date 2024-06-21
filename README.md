# Master-GUI-Framework

A GUI framework for the Spring Engine. For support, MasterBel2 can be contacted at untakenprefix🍎gmail.com

## Index

- [Setup](#Setup)
- [Using MasterFamework to build your UI](#Using-MasterFramework-to-build-your-UI)
 - [Showing a UI on-screen](#Showing-a-UI-on-screen)
 - [Layout Components](#Layout-Components)
 - [Drawing](#Drawing)
- [Contributing to MasterFramework](#Contributing-to-MasterFramework)

## Setup

### Installation

Copy/symlink `gui_master_framework_42.lua` to your Spring installation's `LuaUI/Widgets/` folder, and the `MasterFramework 42` folder to your `LuaUI/` folder, forming the path `LuaUI/MasterFramework 42/`.

As a result, your LuaUI directory should look like this:
```
LuaUI/
    MasterFramework 42/
    Widgets/
        gui_master_framework_42.lua
        ...
    ...
```

Once installed, make sure you enable `MasterBel2's GUI Framework (42)` in Widget Selector. See [below](#Using-MasterFramework-to-build-your-UI) for how to use MasterFramework in your project.

### Importing MasterFramework

MasterFramework supports multiple installed versions, available in the table `WG.MasterFramework` after the widget handler calls `widget:Initialize()` on the framework.
The framework version number is the table key for the instance of MasterFramework; e.g. MasterFramework 42 can be accessed via `WG.MasterFramework[42]`.
See the example below:

```lua
local framework
local requiredFrameworkVersion = 42

widget:Initialize()
    MasterFramework = WG["MasterFramework " .. requiredFrameworkVersion]
    if not MasterFramework then
        error("[WidgetName] Error: MasterFramework " .. requiredFrameworkVersion .. " not found! Removing self.")
    end
end
```

Note: MasterFramework is positioned on layer `-2` (for convenient relationship to BAR's default UI). Widgets on a lower layer must delay their initialisation to account for this.

## Using MasterFramework to build your UI:

This framework provides a group of basic UI components that can be combined and extended to build a complex UI. 
Most components will simply govern the layout of other components (see [Layout Components](#Layout-Components), but components can also register to a draw group to draw graphics on-screen (see [Drawable Components](#Drawable-Components)).

To be registered for drawing, an interface must meet certain criteria: see [#Showing-A-UI-on-screen] for details.

### Showing a UI on-screen

At the top-level, MasterFramework provides an API to show a collection of self-contained UIs - termed [Elements](#Elements).

An `element` is simply a metadata surrounding a top-level component, with some requirements:
- a [layout component](#Layout-Components) provided as the top-level component of the element, containing the entire interface to be shown and determining where on-screen it should be shown
- a human-readable name for the element, solely for providing debug information in case of an error
- a [`MasterFramework.layerRequest`](#Layers) to roughly inform the framework which elements your element should be shown before/behind
- a single [`MasterFramework:PrimaryFrame`](#Primary-Frame) to exist in the draw hierarchy, which provides information about the element's size and position to the framework - primarily for user interaction. An element without a `PrimaryFrame` may successfully layout and draw, but it will not be user-interactive.

Top-level components are provided the entire screen space to be drawn, and may freely decide how they lay themselves out, with no restrictions. Use [Layout Components](#Layout-Components) to restrict where your 

An example of element creation is shown below: 

```lua
key = MasterFramework:InsertElement(
	MasterFramework:PrimaryFrame(
	    MasterFramework:Text("Hello world!")
	),
	"MasterFramework Example",
	MasterFramework.layerRequest.anywhere()
)
```

### Layout Components

Layout components must implement two functions: 
- `component:Layout(availableWidth, availableHeight)`, which returns the calculated `width, height` of the component, usually informed by the available space and the size of any child components. There is no strict requirement that `width <= availableWidth` or `height <= availableWidth`, but following this convention is strictly reccommended.
- `component:Position(x, y)`, which returns nothing, but should inform any child components of their calculated position. 

You may consider that size is decided by the children, while position is decided by the parent. 

See [https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Layout] for examples.

### Drawing

While drawing can technically happen anywhere in layout/position calls, prefer to use groups (see [MasterFramework:DrawGroup](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Drawing/DrawingGroup.lua), [MasterFramework:TextGroup](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Drawing/Text/TextGroup.lua)). 
MasterFramework's provided components rely on groups to provide greater control and performance; groups delay drawing of registered components, and thus drawing operations that happen outside of groups will be out-of-order.

To draw in a group, register your component for drawing in `component:Position` - `table_insert(MasterFramework.activeDrawingGroup.drawTargets, self)` - and implement `component:Draw`, where you can perform your draw operations. 
See [MasterFramework:Rect](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Drawing/DrawingGroup.lua)

Text is grouped separately to other draw operations: use `MasterFramework.activeTextGroup:AddElement(self)` instead. 
Text elements must also provide `textElement._readOnly_font` that stores an instance of [MasterFramework:Font](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Drawing/Text/Font.lua). 
`textElement:Draw()` will be called between `glFont:Begin()` and `glFont:End()`, and be provided a reference to `glFont` for use in drawing.

Every draw group also wraps its children in a text group, to ensure text is always drawn on top of UI components. If alternative behaviour is required, you will (currently) have to provide a custom implementation of DrawGroup.

### Scaling

Many components are designed to automatically adapt to screen size changes. Rather than taking integer sizes, they require a function that will provide a scaled value on demand.

The framework provides [MasterFramework:AutoScalingDimension](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/scaling.lua) which automatically scales a provided constant with the screen size.

### Performance

To avoid unnecessary re-drawing of components you know will not change every frame, wrap them in a [MasterFramework:Rasterizer](https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042/Drawing/Rasterizer.lua).

### Debugging

MasterFramework provides some 

### Barebones Example

Shows "Hello World" In the lower left-hand corner of the screen:

```lua
function widget:GetInfo()
    return {
        name = "MasterFramework Example"
    }
end

local MasterFramework
local requiredFrameworkVersion = 42

local key

function widget:Initialize()
    MasterFramework = WG["MasterFramework " .. requiredFrameworkVersion]
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

## Contributing to MasterFramework

Some brief notes on the internal code of MasterFramework (i.e. within the `MasterFramework 42/` folder):

- The global environment (also the `framework` entry in the global environment) refers to the framework itself, that is registered in `WG.MasterFramework[42]`. 
- A table `Internal` is provided in the global environment during framework initialisation only; this should be cached if needed. Post initialisation, it is removed from the global environment, to restrict access to users of the framework.
- A table `Include` is provided in the global environment during framework initialisation only; this provides access to a portion of the standard global environment. This is also removed post-initialisation, to reduce unneccessary clutter.
- Code is loaded in an unpredictable order; avoid top-level code in these files if at all possible. Instead, provide any necessary initialisation in [https://github.com/MasterBel2/Master-GUI-Framework/tree/main/gui_master_framework_42.lua] after the contents of [https://github.com/MasterBel2/Master-GUI-Framework/tree/main/MasterFramework%2042] have been loaded.

