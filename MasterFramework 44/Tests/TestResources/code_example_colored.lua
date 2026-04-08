ÿªUfunction ÿÿªUwidget:ÿÿªUGetInfo()
    ÿªUreturn {
        ÿÿªUname = ÿªU"Lua File Editor",
        ÿÿªUdescription = ÿªU"",
        ÿÿªUauthor = ÿªU"MasterBel2",
        ÿÿªUdate = ÿªU"April 2023",
        ÿÿªUlicense = ÿªU"GNU GPL, v2 or later",
        ÿÿªUlayer = ÿÿªUmath.ÿÿªUhuge,
        ÿÿªUhandler = ÿªUtrue
    }
ÿªUend

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- MasterFramework
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUlocal ÿÿªUMasterFramework
ÿªUlocal ÿÿªUrequiredFrameworkVersion = ÿªU"Dev"
ÿªUlocal ÿÿªUkey

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Imports
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUlocal ÿÿªUmath_max = ÿÿªUmath.ÿÿªUmax
ÿªUlocal ÿÿªUmath_min = ÿÿªUmath.ÿÿªUmin

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Interface
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUlocal ÿªUfunction ÿÿªUTakeAvailableHeight(ÿÿªUbody)
    ÿªUlocal ÿÿªUcachedHeight
    ÿªUlocal ÿÿªUcachedAvailableHeight
    ÿªUreturn {
        ÿÿªULayout = ÿªUfunction(ÿÿªU_, ÿÿªUavailableWidth, ÿÿªUavailableHeight)
            ÿªUlocal ÿÿªUwidth, ÿÿªUheight = ÿÿªUbody:ÿÿªULayout(ÿÿªUavailableWidth, ÿÿªUavailableHeight)
            ÿÿªUcachedHeight = ÿÿªUheight
            ÿÿªUcachedAvailableHeight = ÿÿªUmath_max(ÿÿªUavailableHeight, ÿÿªUheight)
            ÿªUreturn ÿÿªUwidth, ÿÿªUcachedAvailableHeight
        ÿªUend,
        ÿÿªUPosition = ÿªUfunction(ÿÿªU_, ÿÿªUx, ÿÿªUy) ÿÿªUbody:ÿÿªUPosition(ÿÿªUx, ÿÿªUy + ÿÿªUcachedAvailableHeight - ÿÿªUcachedHeight) ÿªUend
    }
ÿªUend
ÿªUlocal ÿªUfunction ÿÿªUTakeAvailableWidth(ÿÿªUbody)
    ÿªUreturn {
        ÿÿªULayout = ÿªUfunction(ÿÿªU_, ÿÿªUavailableWidth, ÿÿªUavailableHeight)
            ÿªUlocal ÿÿªU_, ÿÿªUheight = ÿÿªUbody:ÿÿªULayout(ÿÿªUavailableWidth, ÿÿªUavailableHeight)
            ÿªUreturn ÿÿªUavailableWidth, ÿÿªUheight
        ÿªUend,
        ÿÿªUPosition = ÿªUfunction(ÿÿªU_, ÿÿªUx, ÿÿªUy) ÿÿªUbody:ÿÿªUPosition(ÿÿªUx, ÿÿªUy) ÿªUend
    }
ÿªUend

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Lexing
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUlocal ÿÿªUkeywords = {
    [ÿªU"function"] = ÿªUtrue,
    [ÿªU"for"] = ÿªUtrue,
    [ÿªU"do"] = ÿªUtrue,
    [ÿªU"if"] = ÿªUtrue,
    [ÿªU"then"] = ÿªUtrue,
    [ÿªU"else"] = ÿªUtrue,
    [ÿªU"elseif"] = ÿªUtrue,
    [ÿªU"repeat"] = ÿªUtrue,
    [ÿªU"until"] = ÿªUtrue,
    [ÿªU"while"] = ÿªUtrue,

    [ÿªU"not"] = ÿªUtrue,
    [ÿªU"and"] = ÿªUtrue,
    [ÿªU"or"] = ÿªUtrue,
    [ÿªU"in"] = ÿªUtrue,

    [ÿªU"nil"] = ÿªUtrue,
    [ÿªU"true"] = ÿªUtrue,
    [ÿªU"false"] = ÿªUtrue,

    [ÿªU"break"] = ÿªUtrue,
    [ÿªU"end"] = ÿªUtrue,
    [ÿªU"return"] = ÿªUtrue,

    [ÿªU"goto"] = ÿªUtrue,
    [ÿªU"local"] = ÿªUtrue
}
ÿªUlocal ÿÿªUtwoCharacterOperators = {
    [ÿªU".."] = ÿªUtrue,
    [ÿªU"~="] = ÿªUtrue,
    [ÿªU"=="] = ÿªUtrue,
    ÿUUU-- ["<<"] = true,
    ÿUUU-- [">>"] = true,
    [ÿªU"<="] = ÿªUtrue,
    [ÿªU"<="] = ÿªUtrue,
	[ÿªU">="] = ÿªUtrue,
}
ÿªUlocal ÿÿªUsingleCharacterOperators = {
    [ÿªU">"] = ÿªUtrue,
    [ÿªU"<"] = ÿªUtrue,
    [ÿªU"="] = ÿªUtrue,
    [ÿªU"."] = ÿªUtrue,
    [ÿªU"-"] = ÿªUtrue,
    [ÿªU"/"] = ÿªUtrue,
    [ÿªU"*"] = ÿªUtrue,
    [ÿªU"%"] = ÿªUtrue,
    [ÿªU"#"] = ÿªUtrue,
    [ÿªU"#"] = ÿªUtrue,
}

ÿªUlocal ÿÿªUpunctuation = {
    [ÿªU","] = ÿªUtrue,
    [ÿªU":"] = ÿªUtrue,
    [ÿªU";"] = ÿªUtrue,
    [ÿªU"("] = ÿªUtrue,
    [ÿªU")"] = ÿªUtrue,
    [ÿªU"["] = ÿªUtrue,
    [ÿªU"]"] = ÿªUtrue,
    [ÿªU"{"] = ÿªUtrue,
    [ÿªU"}"] = ÿªUtrue,
}

ÿªUlocal ÿÿªUwhitespace = {
    [ÿªU" "] = ÿªUtrue,
    [ÿªU"\t"] = ÿªUtrue,
    [ÿªU"\r"] = ÿªUtrue,
    [ÿªU"\n"] = ÿªUtrue,
}

ÿªUlocal ÿÿªUkeywordOrAttributePrimaryCharacterSet = ÿªU"[%a_]"
ÿªUlocal ÿÿªUkeywordOrAttributeSecondaryCharacterSet = ÿªU"[%a%d_]"
ÿªUlocal ÿÿªUnumberLiteralPrimaryCharacterSet = ÿªU"%d"
ÿªUlocal ÿÿªUnumberLiteralSecondaryCharacterSet = ÿªU"[%d_.]"
ÿªUlocal ÿÿªUnumberLiteralTertiaryCharacterSet = ÿªU"[%d_]"
ÿªUlocal ÿÿªUoperatorCharacterSet = ÿªU"[#=%+%-%*/%%%^&~|<>=%.]"

ÿªUlocal ÿÿªUTOKEN_TYPE_STRING_LITERAL = ÿUª1
ÿªUlocal ÿÿªUTOKEN_TYPE_UNCLOSED_STRING_LITERAL = ÿUª2
ÿªUlocal ÿÿªUTOKEN_TYPE_KEYWORD = ÿUª3
ÿªUlocal ÿÿªUTOKEN_TYPE_ATTRIBUTE = ÿUª4
ÿªUlocal ÿÿªUTOKEN_TYPE_NUMBER_LITERAL = ÿUª5
ÿªUlocal ÿÿªUTOKEN_TYPE_MULTILINE_COMMENT = ÿUª6
ÿªUlocal ÿÿªUTOKEN_TYPE_COMMENT = ÿUª7
ÿªUlocal ÿÿªUTOKEN_TYPE_OPERATOR = ÿUª8
ÿªUlocal ÿÿªUTOKEN_TYPE_INVALID_CHARACTER = ÿUª9
ÿªUlocal ÿÿªUTOKEN_TYPE_MULTILINE_STRING_LITERAL = ÿUª10
ÿªUlocal ÿÿªUTOKEN_TYPE_PUNCTUATION = ÿUª11
ÿªUlocal ÿÿªUTOKEN_TYPE_WHITESPACE = ÿUª12

ÿªUlocal ÿªUfunction ÿÿªUlexStringLiteral(ÿÿªUstring, ÿÿªUstartIndex, ÿÿªUterminator)
    ÿªUlocal ÿÿªUnextIndex = ÿÿªUstartIndex
    ÿªUlocal ÿÿªUescaped

    ÿªUwhile ÿÿªUnextIndex <= ÿÿªUstring:ÿÿªUlen() ÿªUdo
        ÿªUlocal ÿÿªUnextCharacter = ÿÿªUstring:ÿÿªUsub(ÿÿªUnextIndex, ÿÿªUnextIndex)
        ÿªUif ÿÿªUescaped ÿªUthen
            ÿÿªUescaped = ÿªUfalse
        ÿªUelse
            ÿªUif ÿÿªUnextCharacter == ÿÿªUterminator ÿªUthen
                ÿªUreturn ÿÿªUTOKEN_TYPE_STRING_LITERAL, ÿÿªUstartIndex - ÿUª1, ÿÿªUnextIndex
            ÿªUelseif ÿÿªUnextCharacter == ÿªU"\n" ÿªUthen
                ÿªUreturn ÿÿªUTOKEN_TYPE_UNCLOSED_STRING_LITERAL, ÿÿªUstartIndex - ÿUª1, ÿÿªUnextIndex
            ÿªUelseif ÿÿªUnextCharacter == ÿªU"\\" ÿªUthen
                ÿÿªUescaped = ÿªUtrue
            ÿªUend
        ÿªUend
        ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1
    ÿªUend

    ÿªUreturn ÿÿªUTOKEN_TYPE_UNCLOSED_STRING_LITERAL, ÿÿªUstartIndex - ÿUª1, ÿÿªUstring:ÿÿªUlen()
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUparseMultiLine(ÿÿªUstring, ÿÿªUstartIndex)
    ÿªUif ÿÿªUstring:ÿÿªUsub(ÿÿªUstartIndex, ÿÿªUstartIndex) ~= ÿªU"[" ÿªUthen
        ÿªUreturn ÿªUnil
    ÿªUend

    ÿªUlocal ÿÿªUlayerCount = ÿUª0
    ÿªUlocal ÿÿªUnextIndex = ÿÿªUstartIndex + ÿUª1

    ÿªUwhile ÿÿªUnextIndex <= ÿÿªUstring:ÿÿªUlen() ÿªUdo
        ÿªUif ÿÿªUstring:ÿÿªUsub(ÿÿªUnextIndex, ÿÿªUnextIndex) == ÿªU"=" ÿªUthen
            ÿÿªUlayerCount = ÿÿªUlayerCount + ÿUª1
            ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1
        ÿªUelseif ÿÿªUstring:ÿÿªUsub(ÿÿªUnextIndex, ÿÿªUnextIndex) == ÿªU"[" ÿªUthen
            ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1
            ÿªUbreak
        ÿªUelse 
            ÿªUreturn ÿªUnil
        ÿªUend
    ÿªUend

    ÿªUlocal ÿÿªUmultilineClose = ÿªU"%]"
    ÿªUfor ÿÿªUi = ÿUª1, ÿÿªUlayerCount ÿªUdo
        ÿÿªUmultilineClose = ÿÿªUmultilineClose .. ÿªU"="
    ÿªUend
    ÿÿªUmultilineClose = ÿÿªUmultilineClose .. ÿªU"%]"
    ÿªUlocal ÿÿªUcommentCloseBegin, ÿÿªUcommentCloseEnd = ÿÿªUstring:ÿÿªUfind(ÿÿªUmultilineClose, ÿÿªUnextIndex)
    
    ÿªUif ÿÿªUcommentCloseBegin ÿªUthen
        ÿªUreturn ÿÿªUcommentCloseEnd
    ÿªUend
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUlex(ÿÿªUstring)
    ÿªUlocal ÿÿªUtokenCount = ÿUª0
    ÿªUlocal ÿÿªUtokenTypes = {}
    ÿªUlocal ÿÿªUtokenStartIndices = {}
    ÿªUlocal ÿÿªUtokenEndIndices = {}

    ÿªUlocal ÿªUfunction ÿÿªUaddToken(ÿÿªUtype, ÿÿªUstartIndex, ÿÿªUendIndex)
        ÿÿªUtokenCount = ÿÿªUtokenCount + ÿUª1
        ÿÿªUtokenTypes[ÿÿªUtokenCount] = ÿÿªUtype
        ÿÿªUtokenStartIndices[ÿÿªUtokenCount] = ÿÿªUstartIndex
        ÿÿªUtokenEndIndices[ÿÿªUtokenCount] = ÿÿªUendIndex
    ÿªUend

    ÿªUlocal ÿÿªUnextIndex = ÿUª1
    
    ÿªUwhile ÿÿªUnextIndex <= ÿÿªUstring:ÿÿªUlen() ÿªUdo
        ÿªUlocal ÿÿªUshouldContinue

        ÿªUlocal ÿÿªUcurrentIndex = ÿÿªUnextIndex
        ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1

        ÿªUlocal ÿÿªUcharacter = ÿÿªUstring:ÿÿªUsub(ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)

        ÿªUif ÿÿªUcharacter:ÿÿªUfind(ÿÿªUkeywordOrAttributePrimaryCharacterSet) ÿªUthen
            ÿªUlocal ÿÿªUstartIndex = ÿÿªUcurrentIndex
            ÿªUwhile ÿÿªUcurrentIndex <= ÿÿªUstring:ÿÿªUlen() ÿªUdo
                ÿªUlocal ÿÿªUcharacter = ÿÿªUstring:ÿÿªUsub(ÿÿªUnextIndex, ÿÿªUnextIndex)
                ÿªUif ÿªUnot ÿÿªUcharacter ÿªUor ÿªUnot ÿÿªUcharacter:ÿÿªUfind(ÿÿªUkeywordOrAttributeSecondaryCharacterSet) ÿªUthen
                    ÿªUlocal ÿÿªUkeywordOrAttribute = ÿÿªUstring:ÿÿªUsub(ÿÿªUstartIndex, ÿÿªUcurrentIndex)
                    ÿªUlocal ÿÿªUtokenType
                    ÿªUif ÿÿªUkeywords[ÿÿªUkeywordOrAttribute] ÿªUthen
                        ÿÿªUtokenType = ÿÿªUTOKEN_TYPE_KEYWORD
                    ÿªUelse
                        ÿÿªUtokenType = ÿÿªUTOKEN_TYPE_ATTRIBUTE
                    ÿªUend

                    ÿÿªUaddToken(ÿÿªUtokenType, ÿÿªUstartIndex, ÿÿªUcurrentIndex)

                    ÿÿªUnextIndex = ÿÿªUcurrentIndex + ÿUª1
                    ÿªUbreak
                ÿªUend

                ÿÿªUcurrentIndex = ÿÿªUnextIndex
                ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1
            ÿªUend

        ÿªUelseif ÿÿªUcharacter:ÿÿªUfind(ÿÿªUnumberLiteralPrimaryCharacterSet) ÿªUthen
            ÿªUlocal ÿÿªUnumberBegin, ÿÿªUnumberEnd = ÿÿªUstring:ÿÿªUfind(ÿªU"[%d_]*[%.x]?[%d_]*", ÿÿªUnextIndex) ÿUUU-- TODO: more fine-grained parsing, what if the decimal point is there, and nothing after it?
            ÿªUif ÿÿªUnumberBegin == ÿÿªUnextIndex ÿªUthen
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_NUMBER_LITERAL, ÿÿªUcurrentIndex, ÿÿªUnumberEnd)
                ÿÿªUnextIndex = ÿÿªUnumberEnd + ÿUª1
            ÿªUelse
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_NUMBER_LITERAL, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
            ÿªUend
        ÿªUelseif ÿÿªUcharacter == ÿªU"-" ÿªUand ÿÿªUstring:ÿÿªUsub(ÿÿªUnextIndex, ÿÿªUnextIndex) == ÿªU"-" ÿªUthen ÿUUU-- comment
            ÿªUlocal ÿÿªUmultilineCommentEndIndex = ÿÿªUparseMultiLine(ÿÿªUstring, ÿÿªUnextIndex + ÿUª1)
            ÿªUif ÿÿªUmultilineCommentEndIndex ÿªUthen
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_MULTILINE_COMMENT, ÿÿªUcurrentIndex, ÿÿªUmultilineCommentEndIndex)
                ÿÿªUnextIndex = ÿÿªUmultilineCommentEndIndex + ÿUª1
            ÿªUelse
                ÿªUlocal ÿÿªUcommentEnd = ÿÿªUstring:ÿÿªUfind(ÿªU"\n", ÿÿªUnextIndex + ÿUª1) ÿªUor ÿÿªUstring:ÿÿªUlen()
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_COMMENT, ÿÿªUcurrentIndex, ÿÿªUcommentEnd)
                ÿÿªUnextIndex = ÿÿªUcommentEnd + ÿUª1
            ÿªUend
        ÿªUelseif ÿÿªUcharacter:ÿÿªUfind(ÿÿªUoperatorCharacterSet) ÿªUthen
            ÿªUif ÿÿªUtwoCharacterOperators[ÿÿªUstring:ÿÿªUsub(ÿÿªUcurrentIndex, ÿÿªUnextIndex)] ÿªUthen
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_OPERATOR, ÿÿªUcurrentIndex, ÿÿªUnextIndex)
                ÿÿªUnextIndex = ÿÿªUnextIndex + ÿUª1
            ÿªUelseif ÿÿªUsingleCharacterOperators[ÿÿªUstring:ÿÿªUsub(ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)] ÿªUthen
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_OPERATOR, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
            ÿªUelse
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_INVALID_CHARACTER, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
            ÿªUend
        ÿªUelseif ÿÿªUcharacter == ÿªU"\'" ÿªUthen
            ÿÿªUaddToken(ÿÿªUlexStringLiteral(ÿÿªUstring, ÿÿªUnextIndex, ÿªU"\'"))
            ÿÿªUnextIndex = ÿÿªUtokenEndIndices[ÿÿªUtokenCount] + ÿUª1
        ÿªUelseif ÿÿªUcharacter == ÿªU"\"" ÿªUthen
            ÿÿªUaddToken(ÿÿªUlexStringLiteral(ÿÿªUstring, ÿÿªUnextIndex, ÿªU"\""))
            ÿÿªUnextIndex = ÿÿªUtokenEndIndices[ÿÿªUtokenCount] + ÿUª1
        ÿªUelseif ÿÿªUcharacter == ÿªU"[" ÿªUthen ÿUUU-- multi-line string literal
            ÿªUlocal ÿÿªUmultilineStringEndIndex = ÿÿªUparseMultiLine(ÿÿªUstring, ÿÿªUcurrentIndex)
            ÿªUif ÿÿªUmultilineStringEndIndex ÿªUthen
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_MULTILINE_STRING_LITERAL, ÿÿªUcurrentIndex, ÿÿªUmultilineStringEndIndex)
                ÿÿªUnextIndex = ÿÿªUmultilineStringEndIndex + ÿUª1
            ÿªUelse
                ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_PUNCTUATION, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
            ÿªUend
        ÿªUelseif ÿÿªUpunctuation[ÿÿªUcharacter] ÿªUthen
            ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_PUNCTUATION, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
        ÿªUelseif ÿÿªUwhitespace[ÿÿªUcharacter] ÿªUthen
            ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_WHITESPACE, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
        ÿªUelse
            ÿÿªUaddToken(ÿÿªUTOKEN_TYPE_INVALID_CHARACTER, ÿÿªUcurrentIndex, ÿÿªUcurrentIndex)
        ÿªUend
    ÿªUend

    ÿªUreturn ÿÿªUtokenCount, ÿÿªUtokenTypes, ÿÿªUtokenStartIndices, ÿÿªUtokenEndIndices
ÿªUend

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Widget Internals
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUlocal ÿÿªUfileName
ÿªUlocal ÿÿªUfilePath
ÿªUlocal ÿÿªUshowFullFilePath

ÿªUlocal ÿÿªUtabBar
ÿªUlocal ÿÿªUsearchEntry

ÿªUlocal ÿÿªUtextEntry
ÿªUlocal ÿÿªUcodeScrollContainer
ÿªUlocal ÿÿªUfileBrowserStackContents

ÿªUlocal ÿÿªUeditedFileColor
ÿªUlocal ÿÿªUsavedFileColor

ÿªUlocal ÿÿªUerrorHighlightColor
ÿªUlocal ÿÿªUsearchHighlightColor
ÿªUlocal ÿÿªUselectedSearchHighlightColor

ÿªUlocal ÿÿªUfileNameText
ÿªUlocal ÿÿªUsaveButton
ÿªUlocal ÿÿªUrevertButton

ÿªUlocal ÿÿªUlastSelectedSearchResult
ÿªUlocal ÿÿªUsearchResults = {}

ÿªUlocal ÿÿªUeditedFiles = {}

ÿªUlocal ÿÿªUfolderMenus = {}
ÿªUlocal ÿÿªUfileButtons = {}

ÿªUlocal ÿÿªUerrors = {}
ÿªUlocal ÿÿªUerrorDisplays = {}
ÿªUlocal ÿÿªUerrorHighlightID

ÿªUlocal ÿÿªUfileNamePattern = ÿªU"([%w%s%._&-]+)/?$"

ÿªUlocal ÿÿªUverticalSplitDividerXCache = {}

ÿªUlocal ÿªUfunction ÿÿªUConfigureErrorHighlight()
    ÿªUif ÿÿªUerrors[ÿÿªUfilePath] ÿªUthen
        ÿªUlocal ÿÿªUlineStarts, ÿÿªUlineEnds = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString():ÿÿªUlines_MasterFramework()
        ÿªUlocal ÿÿªUline = ÿÿªUerrors[ÿÿªUfilePath].ÿÿªUline

        ÿªUif ÿÿªUerrorHighlightID ÿªUthen
            ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUUpdateHighlight(ÿÿªUerrorHighlightID, ÿÿªUerrorHighlightColor, ÿÿªUlineStarts[ÿÿªUline], ÿÿªUlineEnds[ÿÿªUline] + ÿUª1)
        ÿªUelse
            ÿÿªUerrorHighlightID = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUHighlightRange(ÿÿªUerrorHighlightColor, ÿÿªUlineStarts[ÿÿªUline], ÿÿªUlineEnds[ÿÿªUline] + ÿUª1)
        ÿªUend
    ÿªUelseif ÿÿªUerrorHighlightID ÿªUthen
        ÿÿªUtextEntry.ÿÿªUtext:ÿÿªURemoveHighlight(ÿÿªUerrorHighlightID)
    ÿªUend
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUSelectFile(ÿÿªUpath, ÿÿªU_fileName, ÿÿªUtargetCharacterIndex)
    ÿÿªUtextEntry.ÿÿªUplaceholder:ÿÿªUSetString(ÿªU"")
    ÿªUif ÿÿªUVFS.ÿÿªUFileExists(ÿÿªUpath, ÿÿªUVFS.ÿÿªURAW) ÿªUthen
        ÿÿªUfileName = ÿÿªU_fileName ÿªUor ÿÿªUpath:ÿÿªUmatch(ÿÿªUfileNamePattern)
        ÿÿªUfilePath = ÿÿªUpath
        ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUSetString(ÿÿªUeditedFiles[ÿÿªUpath] ÿªUor ÿÿªUVFS.ÿÿªULoadFile(ÿÿªUpath))
        ÿªUif ÿÿªUtextEntry.ÿÿªUtext.ÿÿªUavailableWidth ÿªUand ÿÿªUtextEntry.ÿÿªUtext.ÿÿªUavailableHeight ÿªUthen
            ÿÿªUtextEntry.ÿÿªUtext:ÿÿªULayout(ÿÿªUtextEntry.ÿÿªUtext.ÿÿªUavailableWidth, ÿÿªUtextEntry.ÿÿªUtext.ÿÿªUavailableHeight)
            ÿªUif ÿÿªUtargetCharacterIndex ÿªUthen
                ÿªUlocal ÿÿªUlineCount = #ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetDisplayString():ÿÿªUsub(ÿUª1, ÿÿªUtextEntry.ÿÿªUtext:ÿÿªURawIndexToDisplayIndex(ÿÿªUtargetCharacterIndex)):ÿÿªUlines_MasterFramework()
                ÿªUlocal ÿÿªUoffset = (ÿÿªUlineCount - ÿUª10) * ÿÿªUtextEntry.ÿÿªUtext.ÿÿªU_readOnly_font:ÿÿªUScaledSize()
                ÿÿªUcodeScrollContainer.ÿÿªUviewport:ÿÿªUSetYOffset(ÿÿªUmath.ÿÿªUmax(ÿUª0, ÿÿªUoffset))
            ÿªUend
            ÿÿªUfileNameDisplay.ÿÿªUvisual:ÿÿªUSetString(ÿÿªUshowFullFilePath ÿªUand ÿÿªUpath ÿªUor ÿÿªUfileName)
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend
ÿªUend


ÿªUlocal ÿªUfunction ÿÿªURevealPath(ÿÿªUpath)
    ÿªUif ÿÿªUpath == ÿªUnil ÿªUor ÿÿªUpath == ÿªU"" ÿªUthen ÿªUreturn ÿªUtrue ÿªUend
    ÿªUif ÿªUnot ÿÿªURevealPath(ÿÿªUpath:ÿÿªUmatch(ÿªU"(.+/)[%w%s%._&-]+/?$")) ÿªUthen
        ÿªUreturn ÿªUfalse
    ÿªUend
    ÿªUif ÿÿªUfileButtons[ÿÿªUpath] ÿªUthen
        ÿÿªUSelectFile(ÿÿªUpath)
        ÿªUreturn ÿªUtrue
    ÿªUelseif ÿÿªUfolderMenus[ÿÿªUpath] ÿªUthen
        ÿÿªUfolderMenus[ÿÿªUpath]:ÿÿªUShowChildren()
        ÿªUreturn ÿªUtrue
    ÿªUelse
        ÿªUreturn ÿªUfalse
    ÿªUend
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUMarkFileEdited(ÿÿªUpath, ÿÿªUisEdited)
    ÿªUif ÿªUnot ÿÿªUpath ÿªUor (ÿÿªUeditedFiles[ÿÿªUpath] ÿªUand ÿÿªUisEdited) ÿªUor ((ÿªUnot ÿÿªUeditedFiles[ÿÿªUpath]) ÿªUand (ÿªUnot ÿÿªUisEdited)) ÿªUthen
        ÿªUreturn
    ÿªUend
    ÿªUlocal ÿÿªUpattern = ÿªU"(.+/)[%w%s%._&-]+/?$"
    
    ÿÿªUfileButtons[ÿÿªUpath].ÿÿªUvisual:ÿÿªUSetBaseColor(ÿÿªUisEdited ÿªUand ÿÿªUeditedFileColor ÿªUor ÿÿªUsavedFileColor)

    ÿªUlocal ÿÿªUchange = ÿÿªUisEdited ÿªUand ÿUª1 ÿªUor -ÿUª1

    ÿªUlocal ÿÿªUtrimmedPath = ÿÿªUpath:ÿÿªUmatch(ÿÿªUpattern)
    ÿªUwhile ÿÿªUtrimmedPath ÿªUand ÿÿªUtrimmedPath ~= ÿªU"" ÿªUdo
        ÿªUlocal ÿÿªUmenu = ÿÿªUfolderMenus[ÿÿªUtrimmedPath]
        ÿÿªUmenu.ÿÿªUeditedSubfileCount = ÿÿªUmenu.ÿÿªUeditedSubfileCount + ÿÿªUchange
        ÿªUif ÿÿªUisEdited ÿªUthen 
            ÿÿªUmenu.ÿÿªUtitle:ÿÿªUSetBaseColor(ÿÿªUeditedFileColor)
        ÿªUelseif ÿÿªUmenu.ÿÿªUeditedSubfileCount == ÿUª0 ÿªUthen
            ÿÿªUmenu.ÿÿªUtitle:ÿÿªUSetBaseColor(ÿÿªUsavedFileColor)
        ÿªUend 
        ÿÿªUtrimmedPath = ÿÿªUtrimmedPath:ÿÿªUmatch(ÿÿªUpattern)
    ÿªUend
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUSave()
    ÿªUif ÿªUnot ÿÿªUfilePath ÿªUthen ÿªUreturn ÿªUend
    ÿªUlocal ÿÿªUfh = ÿÿªUio.ÿÿªUopen(ÿÿªUfilePath, ÿªU"w")
    ÿÿªUfh:ÿÿªUwrite(ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString())
    ÿÿªUfh:ÿÿªUclose()
    
    ÿÿªUMarkFileEdited(ÿÿªUfilePath, ÿªUfalse)
    ÿÿªUeditedFiles[ÿÿªUfilePath] = ÿªUnil
ÿªUend

ÿªUfunction ÿÿªUwidget:ÿÿªUGetConfigData()
    ÿªUreturn {
        ÿÿªUeditedFiles = ÿÿªUeditedFiles,
        ÿÿªUfilePath = ÿÿªUfilePath,
        ÿÿªUverticalSplitDividerXCache = ÿÿªUverticalSplitDividerXCache
    }
ÿªUend
ÿªUfunction ÿÿªUwidget:ÿÿªUSetConfigData(ÿÿªUdata)
    ÿÿªUeditedFiles = ÿÿªUdata.ÿÿªUeditedFiles
    ÿÿªUfilePath = ÿÿªUdata.ÿÿªUfilePath
    ÿÿªUverticalSplitDividerXCache = ÿÿªUdata.ÿÿªUverticalSplitDividerXCache ÿªUor {}
    ÿªUfor ÿÿªUpath, ÿÿªU_ ÿªUin ÿÿªUpairs(ÿÿªUeditedFiles) ÿªUdo
        ÿÿªUMarkFileEdited(ÿÿªUpath, ÿªUtrue)
    ÿªUend
ÿªUend

ÿªUlocal ÿÿªUtokenTypeColors = {
    [ÿÿªUTOKEN_TYPE_STRING_LITERAL] = ÿªU"\255\001\170\085",
    [ÿÿªUTOKEN_TYPE_MULTILINE_STRING_LITERAL] = ÿªU"\255\001\170\085",
    [ÿÿªUTOKEN_TYPE_COMMENT] = ÿªU"\255\085\085\085",
    [ÿÿªUTOKEN_TYPE_MULTILINE_COMMENT] = ÿªU"\255\085\085\085",
    [ÿÿªUTOKEN_TYPE_NUMBER_LITERAL] = ÿªU"\255\001\085\170",
    [ÿÿªUTOKEN_TYPE_KEYWORD] = ÿªU"\255\170\001\085",
    [ÿÿªUTOKEN_TYPE_ATTRIBUTE] = ÿªU"\255\255\170\085",
}

ÿªUlocal ÿªUfunction ÿÿªUUIFileButton(ÿÿªUpath)
    ÿªUlocal ÿÿªU_fileName = ÿÿªUpath:ÿÿªUmatch(ÿÿªUfileNamePattern)
    ÿªUlocal ÿÿªUbutton = ÿÿªUMasterFramework:ÿÿªUButton(ÿÿªUMasterFramework:ÿÿªUText(ÿÿªU_fileName, ÿÿªUeditedFiles[ÿÿªUpath] ÿªUand ÿÿªUeditedFileColor ÿªUor ÿÿªUsavedFileColor), ÿªUfunction()
        ÿÿªUSelectFile(ÿÿªUpath, ÿÿªU_fileName)
    ÿªUend)

    ÿÿªUfileButtons[ÿÿªUpath] = ÿÿªUbutton

    ÿªUfunction ÿÿªUbutton:ÿÿªUDeregister()
        ÿÿªUfileButtons[ÿÿªUpath] = ÿªUnil
    ÿªUend

    ÿªUreturn ÿÿªUbutton
ÿªUend
ÿªUlocal ÿªUfunction ÿÿªUUIFolderMenu(ÿÿªUpath)
    ÿªUlocal ÿÿªUfolderMenu
    ÿªUlocal ÿÿªUcontentsVisible = ÿªUfalse
    ÿªUlocal ÿÿªUspacing = ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª2)

    ÿªUlocal ÿÿªUcheckBox = ÿÿªUMasterFramework:ÿÿªUCheckBox(ÿUª12, ÿªUfunction(ÿÿªU_, ÿÿªUchecked)
        ÿªUif ÿÿªUchecked ÿªUthen
            ÿÿªUfolderMenu:ÿÿªUShowChildren()
        ÿªUelse
            ÿÿªUfolderMenu:ÿÿªUHideChildren()
        ÿªUend
    ÿªUend)
    ÿªUlocal ÿÿªUtitle = ÿÿªUMasterFramework:ÿÿªUText(ÿÿªUpath:ÿÿªUmatch(ÿªU"([%w%s%._&-]+)/?$") ÿªUor ÿªU"error")

    ÿªUlocal ÿÿªUregisteredChildren

    ÿªUlocal ÿªUfunction ÿÿªUderegisterChildren()
        ÿªUif ÿÿªUregisteredChildren ÿªUthen
            ÿªUfor ÿÿªU_, ÿÿªUchild ÿªUin ÿÿªUipairs(ÿÿªUregisteredChildren) ÿªUdo
                ÿÿªUchild:ÿÿªUDeregister()
            ÿªUend
        ÿªUend

        ÿÿªUregisteredChildren = ÿªUnil
    ÿªUend

    ÿªUlocal ÿÿªUfolderRow = ÿÿªUMasterFramework:ÿÿªUHorizontalStack({ ÿÿªUcheckBox, ÿÿªUtitle }, ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª8), ÿUª0.5)

    ÿÿªUfolderMenu = ÿÿªUMasterFramework:ÿÿªUVerticalStack({ ÿÿªUfolderRow }, ÿÿªUspacing, ÿUª0)

    ÿªUfunction ÿÿªUfolderMenu:ÿÿªUDeregister()
        ÿÿªUderegisterChildren()
        ÿÿªUfolderMenus[ÿÿªUpath] = ÿªUnil
    ÿªUend

    ÿªUfunction ÿÿªUfolderMenu:ÿÿªUShowChildren()
        ÿªUif ÿªUnot ÿÿªUfolderMenu:ÿÿªUGetMembers()[ÿUª2] ÿªUthen
            ÿÿªUregisteredChildren = ÿÿªUtable.ÿÿªUjoinArrays({ ÿÿªUtable.ÿÿªUimap(ÿÿªUVFS.ÿÿªUSubDirs(ÿÿªUpath, ÿªU"*", ÿÿªUVFS.ÿÿªURAW), ÿªUfunction(ÿÿªU_, ÿÿªUsubDir) ÿªUreturn ÿÿªUUIFolderMenu(ÿÿªUsubDir) ÿªUend), ÿÿªUtable.ÿÿªUimap(ÿÿªUVFS.ÿÿªUDirList(ÿÿªUpath, ÿªU"*", ÿÿªUVFS.ÿÿªURAW), ÿªUfunction(ÿÿªU_, ÿÿªUfilePath) ÿªUreturn ÿÿªUUIFileButton(ÿÿªUfilePath) ÿªUend) })
            ÿÿªUfolderMenu:ÿÿªUSetMembers({ ÿÿªUfolderRow, ÿÿªUMasterFramework:ÿÿªUMarginAroundRect(
                ÿÿªUMasterFramework:ÿÿªUVerticalStack(ÿÿªUregisteredChildren, ÿÿªUspacing, ÿUª0),
                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20),
                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0),
                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0),
                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0)
            ) })
        ÿªUend
        ÿÿªUcheckBox:ÿÿªUSetChecked(ÿªUtrue)
    ÿªUend
    ÿªUfunction ÿÿªUfolderMenu:ÿÿªUHideChildren()
        ÿªUif ÿÿªUself:ÿÿªUGetMembers()[ÿUª2] ÿªUthen
            ÿÿªUfolderMenu:ÿÿªUSetMembers({ ÿÿªUfolderRow })
            ÿÿªUderegisterChildren()
        ÿªUend
        ÿÿªUcheckBox:ÿÿªUSetChecked(ÿªUfalse)
    ÿªUend

    ÿÿªUfolderMenu.ÿÿªUeditedSubfileCount = ÿUª0

    ÿªUlocal ÿÿªUescapedPath = ÿÿªUpath:ÿÿªUgsub(ÿªU"([%-%.])", ÿªU"%%%1")

    ÿªUfor ÿÿªUeditedFilePath, ÿÿªU_ ÿªUin ÿÿªUpairs(ÿÿªUeditedFiles) ÿªUdo
        ÿªUif ÿÿªUeditedFilePath:ÿÿªUfind(ÿªU"^" .. ÿÿªUpath) ÿªUthen
            ÿÿªUfolderMenu.ÿÿªUeditedSubfileCount = ÿÿªUfolderMenu.ÿÿªUeditedSubfileCount + ÿUª1
        ÿªUend
    ÿªUend

    ÿªUif ÿÿªUfolderMenu.ÿÿªUeditedSubfileCount == ÿUª0 ÿªUthen
        ÿÿªUtitle:ÿÿªUSetBaseColor(ÿÿªUsavedFileColor)
    ÿªUelse
        ÿÿªUtitle:ÿÿªUSetBaseColor(ÿÿªUeditedFileColor)
    ÿªUend

    ÿÿªUfolderMenu.ÿÿªUtitle = ÿÿªUtitle

    ÿÿªUfolderMenus[ÿÿªUpath] = ÿÿªUfolderMenu

    ÿªUreturn ÿÿªUfolderMenu
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUVerticalSplit(ÿÿªUleft, ÿÿªUright, ÿÿªUyAnchor, ÿÿªUkey)
    ÿªUlocal ÿÿªUsplit = ÿÿªUMasterFramework:ÿÿªUComponent(ÿªUtrue, ÿªUfalse)
    ÿªUlocal ÿÿªUisDragging

    ÿªUlocal ÿÿªUminWidth = ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª40)

    ÿªUlocal ÿÿªUdividerWidth = ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª2)
    ÿªUlocal ÿÿªUwidth, ÿÿªUheight
    ÿªUlocal ÿÿªUdividerRect = ÿÿªUMasterFramework:ÿÿªUBackground(ÿÿªUMasterFramework:ÿÿªURect(ÿÿªUdividerWidth, ÿªUfunction() ÿªUreturn ÿÿªUheight ÿªUend), { ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUhoverColor }, ÿªUnil)

    ÿªUlocal ÿÿªUpreviousScale = ÿÿªUMasterFramework.ÿÿªUcombinedScaleFactor

    ÿªUlocal ÿÿªUdragStartX
    ÿªUlocal ÿÿªUdividerStartX
    ÿªUlocal ÿÿªUdividerX = (ÿÿªUverticalSplitDividerXCache[ÿÿªUkey] ÿªUor ÿUª100) * ÿÿªUpreviousScale

    ÿªUlocal ÿÿªUhoverColor = ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUhoverColor

    ÿªUlocal ÿÿªUdivider = ÿÿªUMasterFramework:ÿÿªUMouseOverChangeResponder(
        ÿÿªUMasterFramework:ÿÿªUMousePressResponder(
            ÿÿªUdividerRect,
            ÿªUfunction(ÿÿªU_, ÿÿªUx)
                ÿÿªUdividerRect:ÿÿªUSetDecorations({ ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUpressColor })
                ÿÿªUisDragging = ÿªUtrue
                ÿÿªUdragStartX = ÿÿªUx
                ÿÿªUdividerStartX = ÿÿªUdividerX
                ÿªUreturn ÿªUtrue
            ÿªUend,
            ÿªUfunction(ÿÿªU_, ÿÿªUx)
                ÿªUlocal ÿÿªUdx = ÿÿªUx - ÿÿªUdragStartX
                ÿÿªUdividerX = ÿÿªUdividerStartX + ÿÿªUdx
                ÿUUU-- dividerX = math_max(math.min((minWidth() - dividerWidth()) / 2, dragStartX + dx), width - math.min((minWidth() - dividerWidth()) / 2))
                ÿÿªUverticalSplitDividerXCache[ÿÿªUkey] = ÿÿªUdividerX / ÿÿªUpreviousScale
                ÿÿªUsplit:ÿÿªUNeedsLayout()
            ÿªUend,
            ÿªUfunction()
                ÿÿªUdividerRect:ÿÿªUSetDecorations({ ÿÿªUhoverColor })
                ÿÿªUisDragging = ÿªUfalse
            ÿªUend
        ),
        ÿªUfunction(ÿÿªUisOver)
            ÿÿªUhoverColor = ÿÿªUisOver ÿªUand ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUselectedColor ÿªUor ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUhoverColor
            ÿªUif ÿªUnot ÿÿªUisDragging ÿªUthen
                ÿÿªUdividerRect:ÿÿªUSetDecorations({ ÿÿªUhoverColor })
            ÿªUend
        ÿªUend
    )

    ÿªUfunction ÿÿªUsplit:ÿÿªULayout(ÿÿªUavailableWidth, ÿÿªUavailableHeight)
        ÿÿªUself:ÿÿªURegisterDrawingGroup()
        ÿªUif ÿÿªUpreviousScale ~= ÿÿªUMasterFramework.ÿÿªUcombinedScaleFactor ÿªUthen
            ÿÿªUdividerX = ÿÿªUdividerX / ÿÿªUpreviousScale * ÿÿªUMasterFramework.ÿÿªUcombinedScaleFactor
            ÿÿªUpreviousScale = ÿÿªUMasterFramework.ÿÿªUcombinedScaleFactor
        ÿªUend

        ÿÿªUdividerX = ÿÿªUmath.ÿÿªUmin(ÿÿªUmath_max((ÿÿªUminWidth() - ÿÿªUdividerWidth()) / ÿUª2, ÿÿªUdividerX), ÿÿªUavailableWidth - (ÿÿªUminWidth() - ÿÿªUdividerWidth()) / ÿUª2)

        ÿªUif ÿÿªUavailableWidth < ÿÿªUminWidth() ÿªUthen
            ÿÿªUavailableWidth = ÿÿªUminWidth()
            ÿÿªUdividerX = ÿÿªUmath.ÿÿªUfloor((ÿÿªUavailableWidth - ÿÿªUdividerWidth()) / ÿUª2)
        ÿªUend

        ÿªUlocal ÿÿªUleftWidth, ÿÿªUleftHeight = ÿÿªUleft:ÿÿªULayout(ÿÿªUdividerX, ÿÿªUavailableHeight)
        ÿªUlocal ÿÿªUrightWidth, ÿÿªUrightHeight = ÿÿªUright:ÿÿªULayout(ÿÿªUavailableWidth - (ÿÿªUleftWidth + ÿÿªUdividerWidth()), ÿÿªUavailableHeight)

        
        ÿÿªUleft.ÿÿªU_split_cachedHeight = ÿÿªUleftHeight
        
        ÿÿªUright.ÿÿªU_split_xOffset = ÿÿªUleftWidth + ÿÿªUdividerWidth()
        ÿÿªUright.ÿÿªU_split_cachedHeight = ÿÿªUrightHeight
        
        ÿÿªUwidth = ÿÿªUleftWidth + ÿÿªUdividerWidth() + ÿÿªUrightWidth
        ÿÿªUheight = ÿÿªUmath_max(ÿÿªUleftHeight, ÿÿªUrightHeight)
        
        ÿÿªUdivider:ÿÿªULayout(ÿÿªUdividerWidth(), ÿÿªUheight)

        ÿªUreturn ÿÿªUwidth, ÿÿªUheight
    ÿªUend
    ÿªUfunction ÿÿªUsplit:ÿÿªUPosition(ÿÿªUx, ÿÿªUy)
        ÿÿªUleft:ÿÿªUPosition(ÿÿªUx, ÿÿªUy + (ÿÿªUheight - ÿÿªUleft.ÿÿªU_split_cachedHeight) * ÿÿªUyAnchor)
        ÿÿªUright:ÿÿªUPosition(ÿÿªUx + ÿÿªUright.ÿÿªU_split_xOffset, ÿÿªUy + (ÿÿªUheight - ÿÿªUright.ÿÿªU_split_cachedHeight) * ÿÿªUyAnchor)
        ÿÿªUdivider:ÿÿªUPosition(ÿÿªUx + ÿÿªUdividerX, ÿÿªUy)
    ÿªUend

    ÿªUreturn ÿÿªUsplit
ÿªUend

ÿªUlocal ÿªUfunction ÿÿªUTabBar(ÿÿªUoptions)
    ÿªUlocal ÿÿªUbox = ÿÿªUMasterFramework:ÿÿªUBox(ÿÿªUMasterFramework:ÿÿªURect(ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0), ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0)))
    ÿªUlocal ÿÿªUbody = ÿÿªUMasterFramework:ÿÿªUMarginAroundRect(
        ÿÿªUbox,
        ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0),
        ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20),
        ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0),
        ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20)
    )

    ÿªUlocal ÿÿªUbuttons = ÿÿªUtable.ÿÿªUimap(ÿÿªUoptions, ÿªUfunction(ÿÿªUindex, ÿÿªUtab)
        ÿªUlocal ÿÿªUtitleText = ÿÿªUMasterFramework:ÿÿªUText(ÿÿªUtab.ÿÿªUtitle)
        ÿªUlocal ÿÿªUbutton = ÿÿªUMasterFramework:ÿÿªUButton(
            ÿÿªUtitleText,
            ÿªUfunction()
                ÿÿªUtabBar:ÿÿªUSelect(ÿÿªUindex)
            ÿªUend
        )

        ÿÿªUbutton.ÿÿªUtitleText = ÿÿªUtitleText
        ÿªUreturn ÿÿªUbutton
    ÿªUend)

    ÿªUlocal ÿÿªUtabBar
    ÿÿªUtabBar = ÿÿªUMasterFramework:ÿÿªUVerticalHungryStack(
        ÿÿªUMasterFramework:ÿÿªUHorizontalStack(ÿÿªUbuttons, ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª8), ÿUª1),
        ÿÿªUTakeAvailableWidth(ÿÿªUbody),
        ÿÿªUMasterFramework:ÿÿªURect(ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0), ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0)),
        ÿUª0.5
    )

    ÿªUlocal ÿÿªUlastSelectedButton
    ÿªUfunction ÿÿªUtabBar:ÿÿªUSelect(ÿÿªUindex)
        ÿªUif ÿªUnot ÿÿªUbuttons[ÿÿªUindex] ÿªUthen ÿªUreturn ÿªUend
        ÿªUif ÿÿªUlastSelectedButton ÿªUthen
            ÿÿªUlastSelectedButton.ÿÿªUtitleText:ÿÿªUSetBaseColor(ÿÿªUMasterFramework:ÿÿªUColor(ÿUª1, ÿUª1, ÿUª1, ÿUª1))
        ÿªUend
        ÿÿªUlastSelectedButton = ÿÿªUbuttons[ÿÿªUindex]
        ÿÿªUbuttons[ÿÿªUindex].ÿÿªUtitleText:ÿÿªUSetBaseColor(ÿÿªUMasterFramework:ÿÿªUColor(ÿUª0.3, ÿUª0.6, ÿUª1, ÿUª1))
        ÿÿªUbox:ÿÿªUSetChild(ÿÿªUoptions[ÿÿªUindex].ÿÿªUdisplay)
    ÿªUend

    ÿÿªUtabBar:ÿÿªUSelect(ÿUª1)

    ÿªUreturn ÿÿªUtabBar
ÿªUend

ÿªUlocal ÿÿªUwidgetPathToWidgetName = {}
ÿªUlocal ÿÿªUwidgetNameToFileName = {}
ÿªUlocal ÿÿªUfileNameToWidgetName = {}
ÿªUlocal ÿÿªUrunningWidgets = {}
ÿªUlocal ÿÿªUmessages = {}

ÿªUfunction ÿÿªUErrorDisplay()
    ÿªUlocal ÿÿªUtext = ÿÿªUMasterFramework:ÿÿªUWrappingText(ÿªU"", ÿÿªUMasterFramework.ÿÿªUcolor.ÿÿªUred)
    ÿªUlocal ÿÿªUerrorDisplay
    ÿÿªUerrorDisplay = ÿÿªUMasterFramework:ÿÿªUButton(ÿÿªUtext, ÿªUfunction()
        ÿªUif ÿÿªUerrorDisplay.ÿÿªUpath ÿªUthen
            ÿÿªUshownError = ÿªUfalse
            ÿªUlocal ÿÿªUlineStarts, ÿÿªUlineEnds = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetDisplayString():ÿÿªUlines_MasterFramework()
            ÿÿªUSelectFile(ÿÿªUerrorDisplay.ÿÿªUpath, ÿªUnil, ÿÿªUlineStarts[ÿÿªUerrors[ÿÿªUerrorDisplay.ÿÿªUpath].ÿÿªUline])
            ÿÿªURevealPath(ÿÿªUerrorDisplay.ÿÿªUpath)
        ÿªUend
    ÿªUend)
    ÿÿªUerrorDisplay.ÿÿªUdescriptionText = ÿÿªUtext

    ÿªUreturn ÿÿªUerrorDisplay
ÿªUend

ÿªUlocal ÿÿªUfailedToLoad = {}

ÿªUlocal ÿÿªUconsoleStrings = {
    [ÿªU"^Loading:  (.*)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUwidgetPath)
        ÿÿªUrunningWidgets[ÿÿªUwidgetPath] = { ÿÿªUenabled = ÿªUtrue }
        ÿÿªUerrorDisplays[ÿÿªUwidgetPath] = ÿªUnil
        ÿÿªUerrors[ÿÿªUwidgetPath] = ÿªUnil
        ÿªUif ÿÿªUwidgetPath == ÿÿªUfilePath ÿªUthen
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend,
    [ÿªU"^Loading widget from user:  (.+[^%s])%s+<([^%s]+)> ...$"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUwidgetName, ÿÿªUfileName)
        ÿUUU-- If we get this, we dont get an "Added" message when the widget is successfully loaded
        ÿÿªUfailedToLoad[ÿªU"LuaUI/Widgets/" .. ÿÿªUfileName] = ÿªUnil
        
        ÿÿªUwidgetNameToFileName[ÿÿªUwidgetName] = ÿÿªUfileName
        ÿÿªUfileNameToWidgetName[ÿÿªUfileName] = ÿÿªUwidgetName
        ÿÿªUwidgetPathToWidgetName[ÿªU"LuaUI/Widgets/" .. ÿÿªUfileName] = ÿÿªUwidgetName
        ÿÿªUrunningWidgets[ÿªU"LuaUI/Widgets/" .. ÿÿªUfileName] = { ÿÿªUenabled = ÿªUtrue }
        ÿÿªUerrorDisplays[ÿªU"LuaUI/Widgets/" .. ÿÿªUfileName] = ÿªUnil
        ÿÿªUerrors[ÿªU"LuaUI/Widgets/" .. ÿÿªUfileName] = ÿªUnil

        ÿªUif ÿÿªUpath == ÿÿªUfilePath ÿªUthen
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend,
    [ÿªU"^Added:  (.*)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUwidgetPath) 
        ÿUUU-- We only get this if the widget was manually enabled by the user, not when the widget is loaded by the game. 
        ÿÿªUrunningWidgets[ÿÿªUwidgetPath] = { ÿÿªUenabled = ÿªUtrue }
        ÿÿªUerrorDisplays[ÿÿªUwidgetPath] = ÿªUnil
        ÿÿªUerrors[ÿÿªUwidgetPath] = ÿªUnil
        ÿªUif ÿÿªUwidgetPath == ÿÿªUfilePath ÿªUthen
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend,
    [ÿªU"^Removed:  (.*)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUwidgetPath) ÿUUU-- disabled by user
        ÿÿªUrunningWidgets[ÿÿªUwidgetPath] = ÿªUnil

        ÿªUif ÿÿªUwidgetPath == ÿÿªUfilePath ÿªUthen
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend,
    [ÿªU"^Failed to load: (.+[^%s])  %((.*)%)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUfileName, ÿÿªUdescription) ÿUUU-- widget crash
        ÿUUU-- failedToLoad[fileName] = 
        ÿÿªUfailedToLoad[ÿÿªUfileName] = ÿÿªUdescription
        ÿªUlocal ÿÿªUpath, ÿÿªUline, ÿÿªUerrorMessage = ÿÿªUdescription:ÿÿªUmatch(ÿªU"%[string \"([^\"]+)\"%]:(%d+): (.*)")
        ÿUUU-- local path = "LuaUI/Widgets/" .. fileName
        ÿªUif ÿÿªUpath ÿªUthen
            ÿÿªUerrors[ÿÿªUpath] = { ÿÿªUmessage = ÿÿªUerrorMessage, ÿÿªUline = ÿÿªUtonumber(ÿÿªUline) }
            ÿÿªUerrorDisplays[ÿÿªUpath] = ÿÿªUerrorDisplays[ÿÿªUpath] ÿªUor ÿÿªUErrorDisplay()
            ÿÿªUerrorDisplays[ÿÿªUpath].ÿÿªUdescriptionText:ÿÿªUSetString(ÿÿªUwidgetPathToWidgetName[ÿÿªUpath] ÿªUor ÿÿªUpath .. ÿªU":" .. ÿÿªUerrorMessage)
            ÿÿªUerrorDisplays[ÿÿªUpath].ÿÿªUpath = ÿÿªUpath
        ÿªUend
    ÿªUend,
    [ÿªU"^Error in ([^%s\n]+)%(%): %[string \"([^\"]+)\"%]:(%d+): (.*)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUfunc, ÿÿªUpath, ÿÿªUline, ÿÿªUerrorMessage)
        ÿÿªUerrors[ÿÿªUpath] = { ÿÿªUmessage = ÿÿªUerrorMessage, ÿÿªUline = ÿÿªUtonumber(ÿÿªUline), ÿÿªUfunc = ÿÿªUfunc }
        ÿÿªUerrorDisplays[ÿÿªUpath] = ÿÿªUerrorDisplays[ÿÿªUpath] ÿªUor ÿÿªUErrorDisplay()
        ÿÿªUerrorDisplays[ÿÿªUpath].ÿÿªUdescriptionText:ÿÿªUSetString(ÿÿªUwidgetPathToWidgetName[ÿÿªUpath] ÿªUor ÿÿªUpath .. ÿªU":" .. ÿÿªUerrorMessage)
        ÿÿªUerrorDisplays[ÿÿªUpath].ÿÿªUpath = ÿÿªUpath

        ÿªUif ÿÿªUpath == ÿÿªUfilePath ÿªUthen
            ÿÿªUConfigureErrorHighlight()
        ÿªUend
    ÿªUend,
    [ÿªU"^Removed widget: (.*)"] = ÿªUfunction(ÿÿªUfullMessage, ÿÿªUwidgetName) ÿUUU-- widget crash
        ÿUUU-- runningWidgets["LuaUI/Widgets/" .. widgetNameToFileName[widgetName]].enabled = false
    ÿªUend
}

ÿªUfunction ÿÿªUwidget:ÿÿªUAddConsoleLine(ÿÿªUmsg)
    ÿªUfor ÿÿªUpattern, ÿÿªUfunc ÿªUin ÿÿªUpairs(ÿÿªUconsoleStrings) ÿªUdo
        ÿªUlocal ÿÿªUreturnValues = { ÿÿªUmsg:ÿÿªUmatch(ÿÿªUpattern) }
        ÿªUif #ÿÿªUreturnValues > ÿUª0 ÿªUthen
            ÿUUU-- if pattern == "Error in ([^%s\n]+)%(%): %[string \"([^\"]+)\"%]:(%d+): (.*)" then
            ÿUUU--     returnValues.msg = msg
            ÿUUU--     table.insert(messages, returnValues)
            ÿUUU-- end
            ÿÿªUfunc(ÿÿªUmsg, ÿÿªUunpack(ÿÿªUreturnValues))
        ÿªUend
    ÿªUend
    ÿªUreturn ÿªUtrue
ÿªUend

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Code Editor Text Entry
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUfunction ÿÿªUWG.ÿÿªULuaTextEntry(ÿÿªUframework, ÿÿªUcontent, ÿÿªUplaceholderText, ÿÿªUsaveFunc)
    ÿªUlocal ÿÿªUmonospaceFont = ÿÿªUframework:ÿÿªUFont(ÿªU"fonts/monospaced/SourceCodePro-Medium.otf", ÿUª12)
    ÿªUlocal ÿÿªUtextEntry = ÿÿªUframework:ÿÿªUTextEntry(ÿÿªUcontent, ÿÿªUplaceholderText, ÿªUnil, ÿÿªUmonospaceFont)
    ÿÿªUtextEntry.ÿÿªUsaveFunc = ÿÿªUsaveFunc

    ÿªUfunction ÿÿªUtextEntry:ÿÿªUSetPostEditEffect(ÿÿªUpostEditEffect)
        ÿªUlocal ÿªUfunction ÿÿªUReplaceEditFunction(ÿÿªUname)
            ÿªUlocal ÿÿªUcachedFunction = ÿÿªUtextEntry[ÿÿªUname]
            ÿÿªUtextEntry[ÿÿªUname] = ÿªUfunction(...)
                ÿÿªUcachedFunction(...)
                ÿÿªUpostEditEffect()
            ÿªUend
        ÿªUend
        ÿÿªUReplaceEditFunction(ÿªU"InsertText")
        ÿÿªUReplaceEditFunction(ÿªU"editUndo")
        ÿÿªUReplaceEditFunction(ÿªU"editRedo")
        ÿÿªUReplaceEditFunction(ÿªU"editBackspace")
        ÿÿªUReplaceEditFunction(ÿªU"editDelete")
    ÿªUend

    ÿªUlocal ÿÿªUtextEntry_KeyPress = ÿÿªUtextEntry.ÿÿªUKeyPress
    ÿªUfunction ÿÿªUtextEntry:ÿÿªUKeyPress(ÿÿªUkey, ÿÿªUmods, ÿÿªUisRepeat)
        ÿªUif ÿÿªUkey == ÿUª0x73 ÿªUand ÿÿªUmods.ÿÿªUctrl ÿªUthen 
            ÿÿªUsaveFunc()
        ÿªUelseif ÿÿªUkey == ÿUª0x09 ÿªUthen
            ÿÿªUself:ÿÿªUeditTab()
        ÿªUend

        ÿªUreturn ÿÿªUtextEntry_KeyPress(ÿÿªUself, ÿÿªUkey, ÿÿªUmods, ÿÿªUisRepeat)
    ÿªUend

    ÿªUfunction ÿÿªUtextEntry:ÿÿªUeditTab()
        ÿªUlocal ÿÿªUrawString = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString()
        ÿªUlocal ÿÿªU_, ÿÿªU_, ÿÿªUspaces = ÿÿªUrawString:ÿÿªUfind(ÿªU"\n([ \t]+)[^\n^ ^\t]")
        ÿÿªUself:ÿÿªUInsertText(ÿÿªUspaces ÿªUor ÿªU"    ")
    ÿªUend

    ÿªUfunction ÿÿªUtextEntry:ÿÿªUeditReturn(ÿÿªUisCtrl)
        ÿªUif ÿÿªUisCtrl ÿªUthen
            ÿÿªUself:ÿÿªUInsertText(ÿªU"\n")
            ÿªUreturn
        ÿªUend

        ÿªUlocal ÿÿªUrawString = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString()
        ÿªUlocal ÿÿªUclipped = ÿÿªUrawString:ÿÿªUsub(ÿUª1, ÿÿªUself.ÿÿªUselectionBegin)
        ÿªUwhile ÿªUtrue ÿªUdo
            ÿªUlocal ÿÿªUlineStart, ÿÿªU_, ÿÿªUspaces, ÿÿªUtext = ÿÿªUclipped:ÿÿªUfind(ÿªU"\n(%s*)([^\n]*)$")
            
            ÿªUif ÿªUnot ÿÿªUlineStart ÿªUthen
                ÿªUlocal ÿÿªUspaces, ÿÿªUtext = ÿÿªUclipped:ÿÿªUmatch(ÿªU"^(%s*)([^\n]*)$")
                ÿÿªUself:ÿÿªUInsertText(ÿªU"\n" .. ÿÿªUspaces)
                ÿªUreturn
            ÿªUend

            ÿªUif ÿÿªUtext:ÿÿªUlen() > ÿUª0 ÿªUthen
                ÿÿªUself:ÿÿªUInsertText(ÿªU"\n" .. ÿÿªUspaces)
                ÿªUreturn
            ÿªUelse
                ÿÿªUclipped = ÿÿªUrawString:ÿÿªUsub(ÿUª1, ÿÿªUlineStart - ÿUª1)
            ÿªUend
        ÿªUend 
    ÿªUend

    ÿªUlocal ÿÿªUtext_Layout = ÿÿªUtextEntry.ÿÿªUtext.ÿÿªULayout
    ÿªUlocal ÿÿªUtext_Position = ÿÿªUtextEntry.ÿÿªUtext.ÿÿªUPosition

    ÿªUlocal ÿÿªUtextHeight
    ÿªUlocal ÿÿªUcodeNumbersWidth
    ÿªUlocal ÿÿªUspacing = ÿÿªUframework:ÿÿªUAutoScalingDimension(ÿUª2)
    ÿªUlocal ÿÿªUcodeNumbersColor = ÿÿªUframework:ÿÿªUColor(ÿUª0.2, ÿUª0.2, ÿUª0.2, ÿUª1)

    ÿªUlocal ÿÿªUtextEntryWidth = ÿUª0
    
    ÿªUlocal ÿÿªUdisplayString

    ÿªUlocal ÿÿªUlineTitles = {}
    ÿªUlocal ÿÿªUlineOffsets = {}
    ÿÿªUtextEntry.ÿÿªUlineOffsets = ÿÿªUlineOffsets
    ÿªUlocal ÿÿªUlineStarts, ÿÿªUlineEnds
    ÿªUlocal ÿÿªUlineCount

    ÿªUlocal ÿÿªUlineHeight
    ÿªUlocal ÿÿªUoldLineHeight

    ÿªUfunction ÿÿªUtextEntry.ÿÿªUtext:ÿÿªULayout(ÿÿªUavailableWidth, ÿÿªUavailableHeight)
        ÿUUU-- framework.startProfile("wrappingText:Layout() - custom layout: update line title widths")
        ÿÿªUlineStarts, ÿÿªUlineEnds = ÿÿªUself:ÿÿªUGetRawString():ÿÿªUlines_MasterFramework()
        ÿÿªUlineHeight = ÿÿªUmonospaceFont:ÿÿªUScaledSize()

        ÿÿªUself.ÿÿªUavailableWidth = ÿÿªUavailableWidth
        ÿÿªUself.ÿÿªUavailableHeight = ÿÿªUavailableHeight

        ÿªUlocal ÿÿªUoldLineCount
        ÿÿªUlineCount = #ÿÿªUlineStarts
        
        ÿÿªUcodeNumbersWidth = ÿUª0

        ÿUUU-- if lineCount ~= oldLineCount or oldLineHeight ~= lineHeight then
        ÿUUU--     oldLineHeight = lineHeight
        ÿUUU--     for i = 1, lineCount do
        ÿUUU--         local lineTitleWidth
        ÿUUU--         local lineTitle = lineTitles[i]
        ÿUUU--         if not lineTitles[i] then
        ÿUUU--             lineTitle = framework:Text(tostring(i), codeNumbersColor, monospaceFont)
        ÿUUU--             lineTitles[i] = lineTitle
        ÿUUU--         end
        ÿUUU--         lineTitleWidth, _ = lineTitle:Layout(math.huge, math.huge)

        ÿUUU--         codeNumbersWidth = math_max(lineTitleWidth, codeNumbersWidth)
        ÿUUU--     end

        ÿUUU--     for i = lineCount + 1, #lineTitles do
        ÿUUU--         lineTitles[i] = nil
        ÿUUU--     end
        ÿUUU-- else
        ÿUUU--     for i = 1, #lineTitles do
        ÿUUU--         lineTitle:Layout(math.huge, math.huge)
        ÿUUU--     end
        ÿUUU-- end


        ÿUUU-- framework.endProfile("wrappingText:Layout() - custom layout: update line title widths") -- negligible apart from first run

        ÿªUlocal ÿÿªUwidth, ÿÿªUheight = ÿÿªUtext_Layout(ÿÿªUself, ÿÿªUavailableWidth - ÿÿªUcodeNumbersWidth - ÿÿªUspacing(), ÿÿªUavailableHeight)

        ÿUUU-- framework.startProfile("wrappingText:Layout() - custom layout: record added newlines")

        ÿÿªUtextHeight = ÿÿªUheight
        ÿÿªUtextEntryWidth = ÿÿªUwidth + ÿÿªUcodeNumbersWidth

        ÿÿªUdisplayString = ÿÿªUself:ÿÿªUGetDisplayString()

        ÿªUlocal ÿÿªUinsertedNewlineCount = ÿUª0
        ÿªUlocal ÿÿªUaddedCharactersIndex = ÿUª1
        ÿªUlocal ÿÿªUremovedSpacesIndex = ÿUª1
        ÿªUlocal ÿÿªUcomputedOffset = ÿUª0

        ÿªUlocal ÿÿªUaddedCharacters = ÿÿªUself.ÿÿªUaddedCharacters
        ÿªUlocal ÿÿªUstring_sub = ÿÿªUdisplayString.ÿÿªUsub
        ÿªUfor ÿÿªUi = ÿUª1, ÿÿªUlineCount ÿªUdo
            ÿªUlocal ÿÿªUlineStartDisplayIndex, ÿÿªU_addedCharactersIndex, ÿÿªU_removedSpacesIndex, ÿÿªU_computedOffset = ÿÿªUself:ÿÿªURawIndexToDisplayIndex(ÿÿªUlineStarts[ÿÿªUi], ÿÿªUaddedCharactersIndex, ÿÿªUremovedSpacesIndex, ÿÿªUcomputedOffset)
            ÿªUfor ÿÿªUi = ÿÿªUaddedCharactersIndex, ÿÿªU_addedCharactersIndex ÿªUdo
                ÿªUlocal ÿÿªUindex = ÿÿªUaddedCharacters[ÿÿªUi]
                ÿªUif ÿÿªUstring_sub(ÿÿªUdisplayString, ÿÿªUindex, ÿÿªUindex) == ÿªU"\n" ÿªUthen
                    ÿÿªUinsertedNewlineCount = ÿÿªUinsertedNewlineCount + ÿUª1
                ÿªUend
            ÿªUend
            ÿÿªUaddedCharactersIndex = ÿÿªU_addedCharactersIndex
            ÿÿªUremovedSpacesIndex = ÿÿªU_removedSpacesIndex
            ÿÿªUcomputedOffset = ÿÿªU_computedOffset

            ÿÿªUlineOffsets[ÿÿªUi] = ÿÿªUi + ÿÿªUinsertedNewlineCount
            ÿUUU-- lineTitles[i]._insertedNewlineCount = insertedNewlineCount
        ÿªUend

        ÿUUU-- framework.endProfile("wrappingText:Layout() - custom layout: record added newlines")

        ÿªUreturn ÿÿªUtextEntryWidth, ÿÿªUheight
    ÿªUend
    ÿªUlocal ÿÿªUplaceholder_Layout = ÿÿªUtextEntry.ÿÿªUplaceholder.ÿÿªULayout
    ÿªUfunction ÿÿªUtextEntry.ÿÿªUplaceholder:ÿÿªULayout(ÿÿªUavailableWidth, ÿÿªUavailableHeight)
        ÿªUlocal ÿÿªUwidth, ÿÿªUheight = ÿÿªUplaceholder_Layout(ÿÿªUself, ÿÿªUavailableWidth - ÿÿªUcodeNumbersWidth - ÿÿªUspacing(), ÿÿªUavailableHeight)
        ÿªUreturn ÿÿªUwidth + ÿÿªUcodeNumbersWidth + ÿÿªUspacing(), ÿÿªUheight
    ÿªUend
    ÿªUlocal ÿÿªUplaceholder_Position = ÿÿªUtextEntry.ÿÿªUplaceholder.ÿÿªUPosition
    ÿªUfunction ÿÿªUtextEntry.ÿÿªUplaceholder:ÿÿªUPosition(ÿÿªUx, ÿÿªUy)
        ÿÿªUplaceholder_Position(ÿÿªUself, ÿÿªUx + ÿÿªUcodeNumbersWidth + ÿÿªUspacing(), ÿÿªUy)
    ÿªUend
    ÿªUfunction ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUPosition(ÿÿªUx, ÿÿªUy)
        ÿUUU-- framework.startProfile("wrappingText:Position() - line numbers")
        ÿªUlocal ÿÿªUrightX = ÿÿªUx + ÿÿªUcodeNumbersWidth
        ÿªUlocal ÿÿªUtopY = ÿÿªUy + ÿÿªUtextHeight
        ÿUUU-- for i = 1, lineCount do
        ÿUUU--     local lineTitle = lineTitles[i]
        ÿUUU--     local width, _ = lineTitle:Size()
        ÿUUU--     lineTitle:Position(rightX - width, topY - lineOffsets[i] * lineHeight)
        ÿUUU-- end
        ÿUUU-- framework.endProfile("wrappingText:Position() - line numbers")
        ÿUUU-- framework.startProfile("wrappingText:Position()")
        ÿÿªUtext_Position(ÿÿªUself, ÿÿªUrightX + ÿÿªUspacing(), ÿÿªUy)
        ÿUUU-- framework.endProfile("wrappingText:Position()")
    ÿªUend
    
    ÿªUfunction ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUColoredString(ÿÿªUstring)

        ÿªUlocal ÿÿªUtokenCount, ÿÿªUtokenTypes, ÿÿªUtokenStartIndices, ÿÿªUtokenEndIndices = ÿÿªUlex(ÿÿªUstring)

        ÿªUlocal ÿÿªUstringComponents = {}
        ÿªUlocal ÿÿªUcomponentIndex = ÿUª1
        ÿªUlocal ÿÿªUcharacterIndex = ÿUª1
        ÿªUlocal ÿÿªUlastWasColored = ÿªUfalse
        ÿªUfor ÿÿªUtokenIndex = ÿUª1, ÿÿªUtokenCount ÿªUdo
            ÿUUU-- local tokenIndex = tokenCount - (i - 1)
            ÿªUlocal ÿÿªUtokenType = ÿÿªUtokenTypes[ÿÿªUtokenIndex]
            ÿªUlocal ÿÿªUcolor = ÿÿªUtokenTypeColors[ÿÿªUtokenType]
            ÿªUif ÿÿªUcolor ÿªUthen
                ÿÿªUlastWasColored = ÿªUtrue
                ÿÿªUstringComponents[ÿÿªUcomponentIndex] = ÿÿªUcolor
                ÿÿªUcomponentIndex = ÿÿªUcomponentIndex + ÿUª1
                ÿÿªUstringComponents[ÿÿªUcomponentIndex] = ÿÿªUstring:ÿÿªUsub(ÿÿªUcharacterIndex, ÿÿªUtokenEndIndices[ÿÿªUtokenIndex])
                ÿÿªUcomponentIndex = ÿÿªUcomponentIndex + ÿUª1
            ÿªUelse
                ÿªUif ÿÿªUlastWasColored ÿªUand (ÿªUnot (ÿÿªUtokenType == ÿÿªUTOKEN_TYPE_WHITESPACE)) ÿªUthen
                    ÿÿªUstringComponents[ÿÿªUcomponentIndex] = ÿªU"\b"
                    ÿÿªUcomponentIndex = ÿÿªUcomponentIndex + ÿUª1
                    ÿÿªUlastWasColored = ÿªUfalse
                ÿªUend
                ÿÿªUstringComponents[ÿÿªUcomponentIndex] = ÿÿªUstring:ÿÿªUsub(ÿÿªUcharacterIndex, ÿÿªUtokenEndIndices[ÿÿªUtokenIndex])
                ÿÿªUcomponentIndex = ÿÿªUcomponentIndex + ÿUª1
            ÿªUend

            ÿÿªUcharacterIndex = ÿÿªUtokenEndIndices[ÿÿªUtokenIndex] + ÿUª1
        ÿªUend

        ÿÿªUSpring.ÿÿªUCreateDir(ÿªU"LuaUI/MasterFramework Dev/Tests/TestResources/")
        ÿªUlocal ÿÿªUfile = ÿÿªUio.ÿÿªUopen(ÿªU"LuaUI/MasterFramework Dev/Tests/TestResources/code_example.lua", ÿªU"w")
        ÿÿªUfile:ÿÿªUwrite(ÿÿªUstring)
        ÿÿªUfile:ÿÿªUclose()

        ÿªUlocal ÿÿªUcoloredString = ÿÿªUtable.ÿÿªUconcat(ÿÿªUstringComponents)

        ÿÿªUfile = ÿÿªUio.ÿÿªUopen(ÿªU"LuaUI/MasterFramework Dev/Tests/TestResources/code_example_colored.lua", ÿªU"w")
        ÿÿªUfile:ÿÿªUwrite(ÿÿªUcoloredString)
        ÿÿªUfile:ÿÿªUclose()


        ÿªUreturn ÿÿªUcoloredString
    ÿªUend

    ÿªUreturn ÿÿªUtextEntry
ÿªUend

ÿUUU------------------------------------------------------------------------------------------------------------
ÿUUU-- Setup/Update/Teardown
ÿUUU------------------------------------------------------------------------------------------------------------

ÿªUfunction ÿÿªUwidget:ÿÿªUUpdate()
    ÿªUlocal ÿÿªUerrors = ÿÿªUtable.ÿÿªUmapToArray(ÿÿªUerrorDisplays, ÿªUfunction(ÿÿªUname, ÿÿªUdisplay) ÿªUreturn { ÿÿªUname = ÿÿªUname, ÿÿªUdisplay = ÿÿªUdisplay } ÿªUend)
    ÿÿªUtable.ÿÿªUsort(ÿÿªUerrors, ÿªUfunction(ÿÿªUa, ÿÿªUb)
        ÿªUreturn ÿÿªUa.ÿÿªUname > ÿÿªUb.ÿÿªUname
    ÿªUend)
    ÿÿªUerrorStack:ÿÿªUSetMembers(ÿÿªUtable.ÿÿªUimap(ÿÿªUerrors, ÿªUfunction(ÿÿªU_, ÿÿªUx) ÿªUreturn ÿÿªUx.ÿÿªUdisplay ÿªUend))
ÿªUend

ÿªUfunction ÿÿªUwidget:ÿÿªUInitialize()
    ÿÿªUMasterFramework = ÿÿªUWG[ÿªU"MasterFramework " .. ÿÿªUrequiredFrameworkVersion]
    ÿªUif ÿªUnot ÿÿªUMasterFramework ÿªUthen
        ÿÿªUerror(ÿªU"[Lua File Editor] MasterFramework " .. ÿÿªUrequiredFrameworkVersion .. ÿªU" not found!")
    ÿªUend

    ÿÿªUerrorHighlightColor = ÿÿªUMasterFramework:ÿÿªUColor(ÿUª1, ÿUª0.2, ÿUª0.1, ÿUª0.5)
    ÿÿªUsearchHighlightColor = ÿÿªUMasterFramework:ÿÿªUColor(ÿUª0.3, ÿUª0.6, ÿUª1, ÿUª0.3)
    ÿÿªUselectedSearchHighlightColor = ÿÿªUMasterFramework:ÿÿªUColor(ÿUª1, ÿUª1, ÿUª0.0, ÿUª0.3)

    ÿÿªUtable = ÿÿªUMasterFramework.ÿÿªUtable

    ÿÿªUtextEntry = ÿÿªUWG.ÿÿªULuaTextEntry(ÿÿªUMasterFramework, ÿªU"", ÿªU"Select File To Edit", ÿÿªUSave)
    ÿªUlocal ÿÿªUtextEntry_KeyPress = ÿÿªUtextEntry.ÿÿªUKeyPress
    ÿªUfunction ÿÿªUtextEntry:ÿÿªUKeyPress(ÿÿªUkey, ÿÿªUmods, ÿÿªUisRepeat)
        ÿªUif ÿÿªUkey == ÿUª0x66 ÿªUand ÿÿªUmods.ÿÿªUctrl ÿªUthen
            ÿÿªUtabBar:ÿÿªUSelect(ÿUª2)
            ÿÿªUsearchEntry:ÿÿªUTakeFocus()
        ÿªUelseif ÿÿªUkey == ÿUª0x72 ÿªUand ÿÿªUmods.ÿÿªUctrl ÿªUthen ÿUUU-- Ctrl+R
            ÿÿªUself.ÿÿªUsaveFunc()
            ÿªUlocal ÿÿªUwidgetName = ÿÿªUwidgetPathToWidgetName[ÿÿªUfilePath]
            ÿªUif ÿÿªUmods.ÿÿªUshift ÿªUthen
                ÿÿªUSpring.ÿÿªUSendCommands(ÿªU"luaui reload")
            ÿªUelseif ÿÿªUwidgetName ÿªUthen
                ÿÿªUwidgetHandler:ÿÿªUDisableWidget(ÿÿªUwidgetName)
                ÿÿªUwidgetHandler:ÿÿªUEnableWidget(ÿÿªUwidgetName)
            ÿªUend
        ÿªUelse
            ÿÿªUtextEntry_KeyPress(ÿÿªUself, ÿÿªUkey, ÿÿªUmods, ÿÿªUisRepeat)
        ÿªUend
    ÿªUend
    

    ÿªUlocal ÿÿªUmonospaceFont = ÿÿªUMasterFramework:ÿÿªUFont(ÿªU"fonts/monospaced/SourceCodePro-Medium.otf", ÿUª12)
    ÿÿªUsearchEntry = ÿÿªUMasterFramework:ÿÿªUTextEntry(ÿªU"", ÿªU"Search", ÿªUnil, ÿÿªUmonospaceFont)
    ÿªUlocal ÿÿªUsearchStack = ÿÿªUMasterFramework:ÿÿªUVerticalStack({}, ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª2), ÿUª0)

    ÿªUfunction ÿÿªUsearchEntry:ÿÿªUSetPostEditEffect(ÿÿªUpostEditEffect)
        ÿªUlocal ÿªUfunction ÿÿªUReplaceEditFunction(ÿÿªUname)
            ÿªUlocal ÿÿªUcachedFunction = ÿÿªUsearchEntry[ÿÿªUname]
            ÿÿªUsearchEntry[ÿÿªUname] = ÿªUfunction(...)
                ÿÿªUcachedFunction(...)
                ÿÿªUpostEditEffect()
            ÿªUend
        ÿªUend
        ÿÿªUReplaceEditFunction(ÿªU"InsertText")
        ÿÿªUReplaceEditFunction(ÿªU"editUndo")
        ÿÿªUReplaceEditFunction(ÿªU"editRedo")
        ÿÿªUReplaceEditFunction(ÿªU"editBackspace")
        ÿÿªUReplaceEditFunction(ÿªU"editDelete")
    ÿªUend

    ÿªUlocal ÿªUfunction ÿÿªUSearch()
        ÿªUlocal ÿÿªUsearchTerm = ÿÿªUsearchEntry.ÿÿªUtext:ÿÿªUGetRawString()

        ÿªUfor ÿÿªU_, ÿÿªUresult ÿªUin ÿÿªUipairs(ÿÿªUsearchResults) ÿªUdo
            ÿÿªU_ = ÿÿªUresult.ÿÿªUhighlightID ÿªUand ÿÿªUtextEntry.ÿÿªUtext:ÿÿªURemoveHighlight(ÿÿªUresult.ÿÿªUhighlightID)
        ÿªUend

        ÿªUif ÿÿªUsearchTerm:ÿÿªUlen() < ÿUª3 ÿªUthen
            ÿÿªUsearchStack:ÿÿªUSetMembers({})
            ÿªUreturn
        ÿªUend

        ÿªUlocal ÿÿªUsearchBegin = ÿUª1
        ÿÿªUsearchResults = {}
        ÿÿªUlastSelectedSearchResult = ÿªUnil
        ÿªUlocal ÿÿªUsearchee = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString()
        ÿªUwhile ÿÿªUsearchBegin < ÿÿªUsearchee:ÿÿªUlen() ÿªUdo
            ÿªUlocal ÿÿªUstart, ÿÿªU_end = ÿÿªUsearchee:ÿÿªUfind(ÿÿªUsearchTerm, ÿÿªUsearchBegin)
            ÿªUif ÿÿªUstart ÿªUand ÿÿªU_end ÿªUthen
                ÿÿªUtable.ÿÿªUinsert(ÿÿªUsearchResults, { 
                    ÿÿªUfilePath = ÿÿªUfilePath, 
                    ÿÿªUstart = ÿÿªUstart, 
                    ÿÿªU_end = ÿÿªU_end, 
                    ÿÿªUhighlightID = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUHighlightRange(ÿÿªUsearchHighlightColor, ÿÿªUstart, ÿÿªU_end + ÿUª1)
                })
                ÿÿªUsearchBegin = ÿÿªU_end + ÿUª1
            ÿªUelse
                ÿªUbreak
            ÿªUend
        ÿªUend

        ÿÿªUsearchStack:ÿÿªUSetMembers(ÿÿªUtable.ÿÿªUimap(ÿÿªUsearchResults, ÿªUfunction(ÿÿªU_, ÿÿªUresult)
            ÿªUreturn ÿÿªUMasterFramework:ÿÿªUButton(
                ÿÿªUMasterFramework:ÿÿªUWrappingText(
                    ÿªU"\255\122\122\122" .. (ÿÿªUsearchee:ÿÿªUsub(ÿUª1, ÿÿªUresult.ÿÿªUstart - ÿUª1):ÿÿªUmatch(ÿªU"[^\n]*[\n][^\n]*$") ÿªUor ÿªU"") .. 
                    ÿªU"\255\255\255\255" .. ÿÿªUsearchee:ÿÿªUsub(ÿÿªUresult.ÿÿªUstart, ÿÿªUresult.ÿÿªU_end) ..
                    ÿªU"\255\122\122\122" .. (ÿÿªUsearchee:ÿÿªUmatch(ÿªU"([^\n]*[\n][^\n]*)", ÿÿªUresult.ÿÿªU_end + ÿUª1) ÿªUor ÿªU"")
                ),
                ÿªUfunction()
                    ÿÿªU_ = ÿÿªUlastSelectedSearchResult ÿªUand ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUUpdateHighlight(ÿÿªUlastSelectedSearchResult.ÿÿªUhighlightID, ÿÿªUsearchHighlightColor, ÿÿªUlastSelectedSearchResult.ÿÿªUstart, ÿÿªUlastSelectedSearchResult.ÿÿªU_end + ÿUª1)
                    ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUUpdateHighlight(ÿÿªUresult.ÿÿªUhighlightID, ÿÿªUselectedSearchHighlightColor, ÿÿªUresult.ÿÿªUstart, ÿÿªUresult.ÿÿªU_end + ÿUª1)
                    ÿÿªUlastSelectedSearchResult = ÿÿªUresult
                    ÿÿªUSelectFile(ÿÿªUresult.ÿÿªUfilePath, ÿªUnil, ÿÿªUresult.ÿÿªUstart)
                ÿªUend
            )
        ÿªUend))
        ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUNeedsRedraw()
    ÿªUend

    ÿÿªUtextEntry:ÿÿªUSetPostEditEffect(ÿªUfunction()
        ÿªUif ÿÿªUfilePath ÿªUthen 
            ÿÿªUMarkFileEdited(ÿÿªUfilePath, ÿªUtrue)
            ÿÿªUeditedFiles[ÿÿªUfilePath] = ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUGetRawString() ÿUUU-- Would be nice to cache the `no file` case also?
        ÿªUend

        ÿÿªUsaveButton.ÿÿªUvisual:ÿÿªUSetString(ÿªU"Save")
        ÿÿªUrevertButton.ÿÿªUvisual:ÿÿªUSetString(ÿªU"Revert")

        ÿÿªUSearch()
    ÿªUend)

    ÿÿªUsearchEntry:ÿÿªUSetPostEditEffect(ÿÿªUSearch)

    ÿÿªUeditedFileColor = ÿÿªUMasterFramework:ÿÿªUColor(ÿUª1, ÿUª0.6, ÿUª0.3, ÿUª1)
    ÿÿªUsavedFileColor = ÿÿªUMasterFramework:ÿÿªUColor(ÿUª1, ÿUª1, ÿUª1, ÿUª1)

    ÿÿªUfileNameDisplay = ÿÿªUMasterFramework:ÿÿªUButton(ÿÿªUMasterFramework:ÿÿªUText(ÿªU"<no file>", ÿÿªUMasterFramework:ÿÿªUColor(ÿUª0.3, ÿUª0.3, ÿUª0.3, ÿUª1)), ÿªUfunction()
        ÿÿªUshowFullFilePath = ÿªUnot ÿÿªUshowFullFilePath
        ÿÿªUfileNameDisplay.ÿÿªUvisual:ÿÿªUSetString(ÿÿªUshowFullFilePath ÿªUand ÿÿªUfilePath ÿªUor ÿÿªUfileName ÿªUor ÿªU"<no file>")
    ÿªUend)
    ÿÿªUsaveButton = ÿÿªUMasterFramework:ÿÿªUButton(ÿÿªUMasterFramework:ÿÿªUText(ÿªU"Save", ÿÿªUMasterFramework:ÿÿªUColor(ÿUª0.3, ÿUª0.3, ÿUª0.6, ÿUª1)), ÿªUfunction(ÿÿªUbutton)
        ÿÿªUSave()
    ÿªUend)
    ÿÿªUrevertButton = ÿÿªUMasterFramework:ÿÿªUButton(ÿÿªUMasterFramework:ÿÿªUText(ÿªU"Revert", ÿÿªUMasterFramework:ÿÿªUColor(ÿUª0.6, ÿUª0.3, ÿUª0.3, ÿUª1)), ÿªUfunction(ÿÿªUbutton)
        ÿªUif ÿªUnot ÿÿªUfilePath ÿªUthen ÿªUreturn ÿªUend
        ÿÿªUtextEntry.ÿÿªUtext:ÿÿªUSetString(ÿÿªUVFS.ÿÿªULoadFile(ÿÿªUfilePath))
        ÿÿªUMarkFileEdited(ÿÿªUfilePath, ÿªUfalse)
        ÿÿªUeditedFiles[ÿÿªUfilePath] = ÿªUnil
    ÿªUend)

    ÿÿªUerrorStack = ÿÿªUMasterFramework:ÿÿªUVerticalStack({}, ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª2), ÿUª0)

    ÿÿªUtabBar = ÿÿªUTabBar({
        { ÿÿªUtitle = ÿªU"Files", ÿÿªUdisplay = ÿÿªUMasterFramework:ÿÿªUVerticalScrollContainer(ÿÿªUUIFolderMenu(ÿÿªULUAUI_DIRNAME)) },
        { ÿÿªUtitle = ÿªU"Search", ÿÿªUdisplay = ÿÿªUMasterFramework:ÿÿªUVerticalHungryStack(ÿÿªUsearchEntry, ÿÿªUMasterFramework:ÿÿªUVerticalScrollContainer(ÿÿªUsearchStack), ÿÿªUMasterFramework:ÿÿªURect(ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0), ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0)), ÿUª0) },
        { ÿÿªUtitle = ÿªU"Errors", ÿÿªUdisplay = ÿÿªUerrorStack }
    })

    ÿÿªUcodeScrollContainer = ÿÿªUMasterFramework:ÿÿªUVerticalScrollContainer(ÿÿªUtextEntry)

    ÿªUlocal ÿÿªUresizableFrame = ÿÿªUMasterFramework:ÿÿªUResizableMovableFrame(
        ÿªU"Lua File Editor",
        ÿÿªUMasterFramework:ÿÿªUPrimaryFrame(
                ÿÿªUMasterFramework:ÿÿªUBackground(
                    ÿÿªUMasterFramework:ÿÿªUMarginAroundRect(
                    ÿÿªUVerticalSplit(
                        ÿÿªUtabBar,
                        ÿÿªUMasterFramework:ÿÿªUVerticalHungryStack(
                            ÿÿªUMasterFramework:ÿÿªUHorizontalStack({
                                    ÿÿªUfileNameDisplay,
                                    ÿÿªUsaveButton,
                                    ÿÿªUrevertButton
                                }, 
                                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª8), ÿUª0.5
                            ),
                            ÿÿªUTakeAvailableWidth(ÿÿªUTakeAvailableHeight(ÿÿªUcodeScrollContainer)),
                            ÿÿªUMasterFramework:ÿÿªURect(ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0), ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª0)), 
                            ÿUª0
                        ),
                        ÿUª1,
                        ÿªU"Lua File Editor Split: Side Bar & Editor 1"
                    ),
                    ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20),
                    ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20),
                    ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20),
                    ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª20)
                ),
                { ÿÿªUMasterFramework.ÿÿªUFlowUIExtensions:ÿÿªUElement() },
                ÿÿªUMasterFramework:ÿÿªUAutoScalingDimension(ÿUª5)
            )
        ),
        ÿÿªUMasterFramework.ÿÿªUviewportWidth * ÿUª0.1, ÿÿªUMasterFramework.ÿÿªUviewportHeight * ÿUª0.1, 
        ÿÿªUMasterFramework.ÿÿªUviewportWidth * ÿUª0.8, ÿÿªUMasterFramework.ÿÿªUviewportHeight * ÿUª0.8,
        ÿªUfalse
    )

    ÿÿªUkey = ÿÿªUMasterFramework:ÿÿªUInsertElement(ÿÿªUresizableFrame, ÿªU"Lua File Editor", ÿÿªUMasterFramework.ÿÿªUlayerRequest.ÿÿªUanywhere())

    ÿªUif ÿÿªUfilePath ÿªUthen
        ÿÿªUSelectFile(ÿÿªUfilePath)
        ÿÿªURevealPath(ÿÿªUfilePath)
    ÿªUend

    ÿªUlocal ÿÿªUbuffer = ÿÿªUSpring.ÿÿªUGetConsoleBuffer()
    ÿªUfor ÿÿªU_, ÿÿªUline ÿªUin ÿÿªUipairs(ÿÿªUbuffer) ÿªUdo
        ÿÿªUwidget:ÿÿªUAddConsoleLine(ÿÿªUline.ÿÿªUtext)
    ÿªUend
ÿªUend

ÿªUfunction ÿÿªUwidget:ÿÿªUShutdown() 
    ÿÿªUMasterFramework:ÿÿªURemoveElement(ÿÿªUkey)
    ÿÿªUWG.ÿÿªUMasterStats = ÿªUnil
ÿªUend