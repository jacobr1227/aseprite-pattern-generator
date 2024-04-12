
local ptn = { _version = "0.0.5" }

--------------------------------------------------------------------------------------
--ENCODE
--------------------------------------------------------------------------------------

local encode
local cOrder = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

local function imageToTable(image)
    --Iterates over an image, generating a table containing positions and colors.
    local imageTable = {
        width = image.width,
        height = image.height,
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
    imageTable.numColors = #colorTable
    return imageTable, colorTable
end

local function compress(body) --Given a ptn body, shrink strings of 3+ identical letters down to number-letter short form.
    local compressed = ""
    local num = 1
    local char = ''
    for x, v in ipairs(body) do
        local i=0
        while i < #v do
            i = i+1
            local currentChar = v:sub(i,i)
            if currentChar ~= char then
                if num >= 3 then
                    v = v:gsub(v:sub(i-num, i-1), num .. char, 1)
                    i = (i-num)+#tostring(num)+1
                end
                char = currentChar
                num = 1
            else
                num = num + 1
                if i >= #v and num >= 3 then
                    v = v:gsub(v:sub((i-num)+1, i), num .. char, 1)
                    num=1
                    char = ''
                end
            end
        end
        compressed = compressed .. v .. "\n"
        char = ''
        num = 1
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
        if #body[x] == imageTable.width then
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
    o = o .. "},width=" .. imageTable.width .. ",height=" .. imageTable.height .. ",numColors=" .. imageTable.numColors .. "\n"
    return o, colorTable
end

encode = function(image) --This will be the main entry, performs all the above functions to convert a given table into a file.
    local imageTable, colorTable = imageToTable(image)
    local header, colors = encodeHeader(imageTable, colorTable)
    local body = compress(generateBody(imageTable, colors))
    return header .. body
end

--Pass in an Image object. Returns a formatted string to be put in a file.
function ptn.encode(image) --The callable function.
    return (encode(image))
end

--------------------------------------------------------------------------------------
--DECODE
--------------------------------------------------------------------------------------

local decode

local function fileToContents(file, contents) --If a given object is a file, then read it.
    local f,err = io.open(file, 'r')
    if f then
        f:close()
        for line in io.lines(file) do
            if not contents.header then
                contents.header = line
            else
                contents.body[#contents.body+1] = line
            end
        end     
    else
        error("invalid file: ", err)
    end
    local tempheader = contents.header
    contents.header = {}
    contents.header.width = tempheader:match("width=(%d+)")
    contents.header.height = tempheader:match("height=(%d+)")
    contents.header.numColors = tempheader:match("numColors=(%d+)")
    contents.header.colors = {}
    for symbol, value in tempheader:gmatch("(%a)=(%d+);") do
        contents.header.colors[symbol] = value
    end
    return contents
end

local function decompress(body) --Given a compressed ptn body, expand the number-letter format back to full length. Returns a stream of characters.
    local retStream = {}
    for line, str in ipairs(body) do
        retStream[line] = str:gsub("(%d+)(%a)", function(a, b) return string.rep(b, a) end)
        print(retStream[line])
    end
    return retStream
end

local function imageify(header, body) --Given contents, reconstruct an image object to return
    local image = Image(header.width, header.height)
    local i, line = 1, 1
    for it in image:pixels() do
        local pixelValue = header.colors[body[line]:sub(i,i)]
        it(pixelValue)
        i = i + 1
        if i > #body[line] then
            line = line + 1
            i = 1
            print(body[line])
        end
    end
    return image
end

decode = function(file, table) --This will be the main entry, performs all the above functions to convert a given file into a table
    local contents = {body={}}
    if type(file) == "table" then --when given a table, optimize out unnecessary processing of information by providing a new field in the header.
        contents.header = file.header
        contents.body = file.body
        for k, c in pairs(contents.header.colors) do
            contents.header.colors[k] = app.pixelColor.rgba(c.red, c.green, c.blue, c.alpha)
        end
    elseif type(file) == "string" then
        contents = fileToContents(file, contents)
    else
        error("Invalid arguments provided! Please provide a valid .ptn file path, or a table.")
    end
    if not contents.header then
        error("Unknown error! Information failed to populate in ptn decoder.")
    end
    local body = decompress(contents.body)
    if table then
        contents.body = body
        for k, color in pairs(contents.header.colors) do
            contents.header.colors[k] = Color{r=app.pixelColor.rgbaR(color),g=app.pixelColor.rgbaG(color),b=app.pixelColor.rgbaB(color),a=app.pixelColor.rgbaA(color)}
        end
        return contents
    else
        local image = imageify(contents.header, body)
        return image
    end
end

--Requires passing either a filename or the pre-read file containing the information. Returns an image object.
function ptn.decode(file, table)
    table = table or false
    return (decode(file, table))
end


return ptn



 