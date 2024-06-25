framework.textEntryStyles = {}
framework.textEntryStyles.selectedStroke = framework:Stroke(framework:AutoScalingDimension(2), framework.color.selectedColor)
framework.textEntryStyles.pressedStroke = framework:Stroke(framework:AutoScalingDimension(2), framework.color.pressColor)
framework.textEntryStyles.defaultBackgroundDecorations = { framework.color.baseBackgroundColor }
framework.textEntryStyles.selectedBackgroundDecorations = { framework.color.baseBackgroundColor, framework.textEntryStyles.selectedStroke }
framework.textEntryStyles.pressedBackgroundDecorations = { framework.color.baseBackgroundColor, framework.textEntryStyles.pressedStroke }