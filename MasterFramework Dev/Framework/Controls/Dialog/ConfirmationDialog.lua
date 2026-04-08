function framework:ConfirmationDialog(title, name, color, action)
    return framework:Dialog(title,
        {},
        {
            { name = name, color = color, action = action },
            { name = "Cancel", color = framework:Color(1, 1, 1, 0.7), action = function() end }
        }
    )
end