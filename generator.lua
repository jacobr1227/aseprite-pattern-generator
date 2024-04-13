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

--helper functions here
local function psuedorandom(n)
    --return 'n' RNs
end

local function blocks(bw, sc, sd, w, h)
    --return vertices, edges in a ratio of the bw constant.
    --This will use some RNs, plus the size of the image, to determine how many of each to limit it to
    --as well as the simple-complex and sparse-dense ratios to prevent unnecessary overcrowding.
end

local function patternSize(ps, w, h)
    --return the size and number of pattern blocks to use
    --Since this operates on a scale of -100 to 100, use that as a frame of reference for the appropriate min/max ratios
end

local function colorize(colors, cm, sd, imageTable)
    --Given the generated image pattern, the color list, the sparsity, and the mix ratio
    --Use the sparsity to occasionally render some squares as the background color
    --return a colorized final table.
end

local function imageify(imageTable, w, h)
    --Convert table to image. Return image.
    local image = Image(w, h)
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
    imageTable = colorize(colors, cm, sd, imageTable)
    return imageify(imageTable, w, h)
end

function gen.generate(args)
    return generate(args)
end

return gen