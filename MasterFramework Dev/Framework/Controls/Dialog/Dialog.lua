function framework:Dialog(titleString, contents, options)
    local dialog
    local dialogKey

    local confirmationDialog

    local dialogTitle = framework:WrappingText(titleString)
    local optionsStack = framework:HorizontalStack(
        table.imap(options, function(_, option)
            return framework:Button(
                framework:Text(option.name, option.color),
                function()
                    if option.confirmation then
                        confirmationDialog = framework:Dialog(
                            option.confirmation.title,
                            {},
                            {
                                { name = option.name, color = option.color, action = function() option.action(); dialog:Hide() end },
                                { name = "Cancel", color = framework:Color(1, 1, 1, 0.7), action = function() end }
                            }
                        )
                        confirmationDialog:PresentAbove(dialogKey)
                    else
                        option.action()
                        dialog:Hide()
                    end
                end
            )
        end),
        framework:AutoScalingDimension(8),
        0
    )

    local editableContents = framework:VerticalStack(contents, framework:AutoScalingDimension(8), 0)

    local dialogBody = framework:VerticalStack( -- TODO: Handling for when there's no  contents?
        { dialogTitle, editableContents, optionsStack },
        framework:AutoScalingDimension(8),
        0
    )

    dialog = framework:PrimaryFrame(
        framework:Background(
            framework:MarginAroundRect(
                framework:FrameOfReference(
                    0.5, 0.5,
                    framework:Background(
                        framework:MarginAroundRect(
                            dialogBody,
                            framework:AutoScalingDimension(20),
                            framework:AutoScalingDimension(20),
                            framework:AutoScalingDimension(20),
                            framework:AutoScalingDimension(20)
                        ),
                        { framework.FlowUIExtensions:Element() },
                        framework:AutoScalingDimension(5)
                    )
                ),
                framework:AutoScalingDimension(0),
                framework:AutoScalingDimension(0),
                framework:AutoScalingDimension(0),
                framework:AutoScalingDimension(0)
            ),
            { framework:Color(0, 0, 0, 0.7) },
            framework:AutoScalingDimension(5)
        )
    )

    dialog.dialog_body = dialogBody
    dialog.dialog_editableContents = editableContents
    dialog.dialog_optionsStack = optionsStack

    function dialog:PresentAbove(elementKeyBelow)
        local layerRequest = framework.layerRequest.directlyAbove(elementKeyBelow)
        if dialogKey then
            framework:MoveElement(dialogKey, layerRequest)
        else
            dialogKey = framework:InsertElement(dialog, "Dialog", layerRequest)
        end
    end

    function dialog:Hide()
        if dialogKey then
            framework:RemoveElement(dialogKey)
            dialogKey = nil
        end
        if confirmationDialog then
            confirmationDialog:Hide()
        end
    end

    function dialog:GetKey()
        return dialogKey
    end

    return dialog
end