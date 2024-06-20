local VFS = Include.VFS

-- NOTE: Order of file loading must be specified to allow for dependencies 
VFS.Include(DIR .. "Constants/color.lua")
VFS.Include(DIR .. "Constants/dimension.lua")
VFS.Include(DIR .. "Constants/stroke.lua") -- depends on color.lua and dimension.lua
VFS.Include(DIR .. "Constants/font.lua")