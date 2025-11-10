Locales = {}

function _U(str, ...)
    if Locales[Config.Locale] and Locales[Config.Locale][str] then
        return string.format(Locales[Config.Locale][str], ...)
    else
        return 'Translation [' .. str .. '] does not exist'
    end
end

function _L(str, ...)
    return _U(str, ...)
end
