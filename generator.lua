--[[
            print("For the sliders:")
            print("Blocky to wavy chooses how rigid the shapes are; how straight or how curvy they'll be.") --vertices vs edges, mathematically
            print("Pattern size chooses how often the pattern will occur, whether it repeats itself constantly with a small pattern, or occupies the entire image at once.")
            print("Simple to complex chooses how complex the pattern will be. Simpler patterns use simpler shapes and are easy to see the pattern in.")
            print("Sparse to dense chooses how much colored space there will be in the image. The background will always be white, so this chooses how much of the image will be the background.")
            print("Color mix determines how mixed each color in the palette will be. Low values will have a given colored pixel be near the same color, where high values will have a given colored pixel be near different colors.")
]]

local gen = {_version = "0.1"}

local generate
local prevSeed = {} -- seed table
local prevHash

--helper functions here
local function pseudohash(str)
    local num = 1
    str = tostring(str)
    for i=#str, 1, -1 do
        num = (((1.7268124753/num))*str:byte(i)*math.pi+math.pi*i)%1
    end
    return num
end

local function pseudorandom(min, max, seed)
    max = max+1-min
    local s = seed
    if seed then
        if prevSeed[seed] then
            seed = pseudohash(prevHash)
            prevSeed[s] = seed
        else
            seed = pseudohash(seed)
            prevSeed[s] = seed
        end
    else 
        if prevHash then
            seed = pseudohash(prevHash)
        else
            math.randomseed(os.time()+(os.clock()*(os.time()%1000))^2)
            for i=1, math.random(2,7) do
                math.random()
            end
            seed = pseudohash(math.random())
        end
        prevHash = seed
    end
    return math.floor(seed*(max))+min
end

local function blocks(bw, ps, sc, sd, w, h, cm, colors)
    local blockSize, horizontal, vertical = patternSize(ps, w, h)
    --create vertices, edges in a ratio of the bw constant.
    --This will use some RNs, plus the size of the image, to determine how many of each to limit it to
    --as well as the simple-complex and sparse-dense ratios to prevent unnecessary overcrowding.
    --High simplicity represents simple regular shapes
    --High complexity represents complex shapes: sub-patterns, branching portions, larger spaces.
    --Low density represents proportionally larger spaces between pattern blocks.
    --High density represents proportionally smaller spaces between pattern blocks, down to 0/1 pixels between each.
    --Uses information from the patternSize function to determine spacings of blocks relative to sparsity
    --Returns the imageTable, with symbolic letters for each of the colors.
end

local function patternSize(ps, w, h)
    --return the size of the pattern block and number of pattern blocks to use in each axis; as well as the spacings for each axis for even placement.
    --Since this operates on a scale of -100 to 100, use that as a frame of reference for the appropriate min/max ratios
    -- patternsize scales from occupying single pixels to occupying the entirety of the smaller of the width/height
    local max = math.min(w,h)
    local min = 1
    if ps < 0 then
        max = 3*max/4+(math.ceil(math.abs(ps/5)))
        min = max/4
    elseif ps > 0 then
        min = ((0.15*math.ceil(ps/5)+1)*max)/4
        max = math.min(3*min, max)
    else
        max = 3*max/4
        min = max/4
    end
    max = math.max(max, 1)
    min = math.max(min, 1)
    local blockSize = pseudorandom(min, max, "psizesd" .. ps)
    local horizontal = {maxBlocks = (w-((w%blockSize)))/blockSize, edgeSpacing = (w%blockSize)-w%2, centerSpacing = w%2}
    local vertical = {maxBlocks = (h-((h%blockSize)))/blockSize, edgeSpacing = (h%blockSize)-h%2, centerSpacing = h%2}
    return blockSize, horizontal, vertical
end

local function imageify(imageTable, w, h)
    --Convert table from symbols to color objects to image pixels. Return image.
    local image = Image(w, h)
    --???
    return image
end

generate = function(args)
    local bw, ps, sc, sd, cm, w, h, colors = args.bw, args.ps, args.sc, args.sd, args.cm, args.width, args.height, args.colors
    local imageTable = {}
    --[[
        Process:
            Generate the blank image table
            Take each nonzero slider value, as well as a random number, and generate some numerical arguments for it
            Then, produce an image unto the table using the given colors.
            Lastly, render the image via the table, and return the image object.
    ]]
    --Use other helper functions here
    imageTable = blocks(bw, ps, sc, sd, w, h, cm, colors)
    return imageify(imageTable, w, h)
end

function gen.generate(args)
    return generate(args)
end

return gen