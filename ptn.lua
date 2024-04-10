--[[
    ptn files are defined as being composed of two parts: a header, and a body.
    All files must be rectangular, with a uniform number of columns in each line.
    The header and body will appear as follows the header (a file with width=5, length=4, with the pattern representing a rectangle in the center, for example)
    
    
    The header will be formatted as follows:
        "alpha"=[true/false],
        "encoding"=[rgb, hex, hsv, hsl],
        "colors"={
            "a"=[string, a color code]; -- all pattern characters represent color codes when decoded. If the alpha channel is enabled, it must be included in this encoding.
            "b"=[string]; -- all single alphabetical or puncuation characters are permitted as pattern names, but *never* numbers. It is CASE SENSITIVE as well, "a" != "A".
            ...                 --This permits a maximum number of channels as 84 with a standard English keyboard. Nonstandard characters are permitted, but use at your own risk.
        },
        "width"=5, --int, the number of columns in a line
        "length"=4 --int, the number of lines in the file


    The final file would look like this:
    alpha=false,encoding=rgb,colors={a=123,123,123;},width=5,length=4;
    aaaaa
    abbba
    abbba
    aaaaa
    --end of file


    Ptn files will support prettification to an extent, so a header like this would work as well:
    alpha=false,
    encoding=rgb,
    color={
        a=123,123,123;
    },
    width=5,
    length=4;
    --body here...



    This format is losslessly compressible at larger scales with repeated strings of information being condensed into numerical counts of a letter, like the following:
    "5a
    a3ba
    a3ba
    5a",
    saving 8 characters on even just a 20 character image.

    
    Colors are encoded as follows (each number below is maximum for its channel: num,num,num[alpha]):
    RGB = "255,255,255,255". Numbers are always represented with triplets. Leading zeroes will be truncated automatically. Brackets will be ignored if alpha is disabled.
    HSV/HSL = "360,100,100[255]"
    Hex = "#FFFFFF" -- Hex will be interpreted as is. There is no alpha channel for hex codes, so they will be automatically set to 255.
]]

--[[TODO:
    Functions:
        Verify
        Save
        Get-Colors
        Get-Size
        Encode-Colors
        Create-Ptn-file
]]

local ptn = { _version = "0.0.1" }

--------------------------------------------------------------------------------------
--ENCODE
--------------------------------------------------------------------------------------

local encode

--[[
    Encoding should take a given image and convert it into a ptn file. Colors need not be provided, as they should already be in the image.
]]

local cOrder = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function imageToTable(image)
    --Iterates over an image, generating a table containing positions and colors.
    local imageTable = {
        width = image.width,
        height = image.height,
        colorMode = image.colorMode,
        image = {}
    }
    local colors = {}
    for it in image:pixels() do
        colors[tostring(it())] = true
        table.insert(imageTable.image, {
            x=it.x,
            y=it.y,
            val=it()
        })
    end
    local colorTable = {}
    for k, _ in pairs(colors) do
        colorTable[#colorTable+1] = {val=k}
    end
    return imageTable, colorTable
end

local function compress(body) --Given a ptn body, shrink strings of 3+ identical letters down to number-letter short form.
    local compressed = ""
    local num = 0
    local char = ''
    for _, v in ipairs(body) do
        for i=1, #v do
            local currentChar = v:sub(i,i)
            if currentChar ~= char then
                if num >= 3 then
                    v = v:gsub(v:sub(i-num, i-1), num .. char)
                    i = i-num
                end
                char = currentChar
                num = 0
                if #v > i then
                    break
                end
            else
                num = num + 1
                if i == #v and num >= 3 then
                    v = v:gsub(v:sub(i-num, i), num .. char)
                end
            end
        end
        compressed = compressed .. v .. "\n"
    end
    return compressed
end

local function generateBody(imageTable, colors) --Given an image, generate a body block.
    local body = {}
    local symbol
    local x = 1
    for i, v in ipairs(imageTable.image) do
        for _, color in ipairs(colors) do
            if tonumber(v.val) == tonumber(color.val) then
                symbol = color.symbol
                break
            end
        end
        if not body[x] then
            body[x] = ""
        end
        body[x] = body[x] .. symbol
        if (v.x % imageTable.width-1) == 0 then
            x = x + 1
        end
    end
    return body
end

local function encodeHeader(imageTable, colorTable) --Given parameters, generate a header line.
    local o = "colors={"
    for i, v in ipairs(colorTable) do
        o = o .. tostring(cOrder:sub(i,i)) .. "=" .. v.val .. ";"
        colorTable[i].symbol = tostring(cOrder:sub(i,i))
    end
    o = o .. "},width=" .. imageTable.width .. ",height=" .. imageTable.height .. ";"
    return o, colorTable
end

encode = function(image) --This will be the main entry, performs all the above functions to convert a given table into a file.
    local imageTable, colorTable = imageToTable(image)
    local header, colors = encodeHeader(imageTable, colorTable)
    local body = compress(generateBody(imageTable, colors))
    return header .. "\n" .. body
end

--Pass in an Image object. Returns a formatted string to be put in a file.
function ptn.encode(image) --The callable function.
    return (encode(image))
end

--------------------------------------------------------------------------------------
--DECODE
--------------------------------------------------------------------------------------

local decode

local function fileToContents() --If a given object is a file and not its contents, then read it.
    
end

local function decompress() --Given a compressed ptn body, expand the number-letter format.
end

local function decodeHeader() --Given a header line/block, return all the necessary file parameters. Should return encoding, color table, width, length, and number of colors
end

decode = function(file) --This will be the main entry, performs all the above functions to convert a given file into a table
end

function ptn.decode(file)
    return (decode(file))
end


return ptn