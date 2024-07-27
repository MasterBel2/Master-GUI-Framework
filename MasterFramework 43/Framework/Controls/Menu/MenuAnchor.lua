--[[
    Displays & positions a menu. 
    
    The menu will automatically be hidden when the mouse is not over it: to keep the menu showing, call `menuAnchor:ShowMenu` every frame you wish for the menu show.

    Parameters:
    - wrappedRect: the component above which the menu will be shown.
    - menuOptions: the `options` argument provided to the created `framework:Menu`. See `framework:Menu`'s documentation for further details.
    - menuLayoutFunc: provides the x, y coordinates for the top-left corner of the menu.
    - menuName: used to determine the menu's key for `framework:InsertElement`. When omitted, we'll default to "Untitled".

    Methods:
    - ShowMenu: If not already showing, shows the menu.
    - HideMenu: If already showing, hides the menu.

    This component is intended to be extended, e.g. `framework:RightClickMenuAnchor`
]]
function framework:MenuAnchor(wrappedRect, menuOptions, menuLayoutFunc, menuName)
    menuName = menuName or "Untitled"

    local menuAnchor = {}

    local menu
    local menuKey

    local cachedX, cachedY
    local width, height

    function menuAnchor:SetMenuOptions(newMenuOptions)
        menuOptions = newMenuOptions
        if menu then
            menu:SetOptions(newMenuOptions)
        end
    end

    menuAnchor:SetMenuOptions(menuOptions)

    -- Trigger bounds may be larger than the bounds of the menuAnchor, so we'll let someone else determine when the menu should show.
    -- 
    -- This must be called every frame that the menu must be shown. 
    function menuAnchor:ShowMenu()
        if (not menu) then
            menu = framework:Menu(menuOptions, self)
            if cachedX and cachedY and width and height then
                menu:SetOffsets(menuLayoutFunc(cachedX, cachedY, width, height, menu))
            end
            menuKey = framework:InsertElement(menu, "Menu: " .. menuName, framework.layerRequest.top())
        end
    end
    
    function menuAnchor:GetMenu()
        return menu
    end

    function menuAnchor:HideMenu()
        if menu then
            framework:RemoveElement(menuKey)
            menu = nil
        end
    end

    function menuAnchor:Layout(availableWidth, availableHeight)
        width, height = wrappedRect:Layout(availableWidth, availableHeight)
        return width, height
    end

    function menuAnchor:Position(x, y)
        wrappedRect:Position(x, y)
        cachedX = x
        cachedY = y
        if menu then
            menu:SetOffsets(menuLayoutFunc(cachedX, cachedY, width, height, menu))
        end
    end

    return menuAnchor
end