local pluginData = ...;

local generator = dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "generator.lua"))
 
function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end
 

local function show()
    local dlg = Dialog("Pattern Generator")
    local patterns = {}

    local function get_pattern(patternName)
        for i, pattern in ipairs(patterns) do
            if pattern.name == patternName then
                return pattern;
            end
        end
        if patternName == nil then return end
        pluginData.logger.Log("Failed to locate pattern '" ..patternName.."'")
    end

    local function save_patterns()
        pluginData.prefs.patternsJson = pluginData.json.encode({data=patterns})
        pluginData.logger.Log("Save Complete.")
    end

    local function set_default_patterns()
        patterns = {
            Example = {name = "Example", file="example.ptn", width=5, height=5, numColors=3}, --TODO: Add below patterns, improve name detail
            bugging = {name="bugging", file="bugging.ptn", width=33,height=42,numColors=10},
            --[[pattern ideas:
                blocks/flat colors
                shaded blocks
                mandelbrot set (1 color)

                some balatro card back patterns
                random triangles (https://magazine.artland.com/wp-content/uploads/2021/07/1986.9-e1588096683282.jpg)
                sierpinski triangle
                other image generative mathematical patterns
                ]]
        }
        for i, v in ipairs(patterns) do
            patterns[i].file = app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", v.file)
        end
    end

    local function load_patterns()
        local loadedPatterns = false
        pluginData.logger.Log("Attempting to load pattern data from preferences.")
        if pluginData.prefs.patternsJson then
            local loaded = pluginData.json.decode(pluginData.prefs.patternsJson)
            if loaded then
                patterns = loaded.data
                loadedPatterns = true
                pluginData.logger.Log("Parsed from json successfully.")
            end
        end

        if loadedPatterns == false then
            set_default_patterns()
        end

        pluginData.logger.Log("Loaded patterns.")
    end

    local function get_pattern_names()
        local names = {}
        for k, pattern in pairs(patterns) do
            names[#names+1] = pattern.name .. " (Width: " .. pattern.width .. ", Height: " .. pattern.height .. ", Number of Colors: " .. pattern.numColors .. ")"
        end
        return names
    end

    local function get_pattern_color_count(name)
        for i, v in ipairs(patterns) do
            if v.name == name then
                return v.numColors
            end
        end
    end

    local function update_pattern(name, data)
        local pattern = get_pattern(name)
        if not pattern then
            app.alert("Pattern not found: " .. name)
        else
            pattern.width = data.width
            pattern.height = data.height
            pattern.name = data.name
            pattern.file = data.file
        end
    end

    local function remove_pattern(name)
        pluginData.logger.Log("Removing pattern: " .. name)
        newPatterns = {}
        for i, pattern in ipairs(patterns) do
            if pattern.name ~= name then
                newPatternCount = newPatternCount+1
                newPatterns[newPatternCount] = pattern
            end
        end
        patterns = newPatterns
        pluginData.logger.Log("Pattern removed.")
    end

    local function get_initial_pattern()
        local sel = ""
        local numColors = 0
        local currentColors = {}
        local colorListP = {}
        if pluginData.prefs.lastSelection then
            local temp = get_pattern(pluginData.prefs.lastSelection)
            if temp then
                sel = pluginData.prefs.lastSelection
                numColors = pluginData.prefs.lastColorCount
                currentColors = pluginData.prefs.lastColors
                colorListP = pluginData.prefs.lastColorListP
            end
        else
            local pattern = patterns[next(patterns)]
            sel = pattern.name .. " (Width: " .. pattern.width .. ", Height: " .. pattern.height .. ", Number of Colors: " .. pattern.numColors .. ")"
            numColors = pattern.numColors
            pluginData.prefs.lastColorCount = numColors
            local temp = pluginData.pattern.decode(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "PatternFiles", pattern.file), true)
            currentColors = temp.header.colors
            pluginData.prefs.lastColors = currentColors
        end
        return sel, numColors, currentColors, colorListP
    end
    
    load_patterns()
    local selection, numColors, currentColors, colorListP = get_initial_pattern()
    local mode = false

    local function create_confirm(str)
        local confirm = Dialog{title="Confirm?", parent=dlg}

        confirm:label {
            id = "text",
            text = str
        }

        confirm:button {
            id = "cancel",
            text = "Cancel",
            onclick = function()
                confirm:close()
            end
        }

        confirm:button {
            id = "confirm",
            text = "Confirm",
            onclick = function()
                confirm:close()
            end
        }

        -- show to grab centered coordinates
        confirm:show { wait = true }

        return confirm.data.confirm
    end

    local function swap_style(create)
        local cvisible = {"fileInfo", "file", "createFromFile"}
        local cinvisible = {"selectionInfo1", "selectionInfo2", "save", "createFromSelection"}
        for i,v in ipairs(cvisible) do
            dlg:modify{id=v,visible=create};
        end
        for i,v in ipairs(cinvisible) do
            dlg:modify{id=v,visible=not create};
        end
    end

    local function swap_tabs(newtab)
        local preset = {"resetButton", "createFromPreset", "colorWarning", "colorWarning2", "blockSeparatorP1", "shadesLabelP", "shadesLabelP2", "shadesListP", "currentShades", "addToShadesP", "colorPickerP", "defaultColors", "patternDropdown", "tabSeparatorP1"}
        local upload = {"tabSeparatorU1", "fromFile", "fromSelection", "blockSeparatorU1", "fileInfo", "file", "createFromFile", "selectionInfo1", "selectionInfo2", "save", "createFromSelection"}
        local generative = {"tabSeparatorG1", "genSize", "width", "height", "blockSeparatorG1", "genColor", "colorPicker", "addToShades", "shadesList", "genPattern", "blocky-wavy", 
            "blockSeparatorG2", "repetitive-unique", "simple-complex", "sparse-dense", "colorSpread", "blockSeparatorG3", "generateFromSettings", "infoButton"}
        local p, u, g = false, false, false
        if newtab == "preset" then p=true
        elseif newtab == "upload" then u=true
        elseif newtab == "generative" then g=true end
        for k, id in ipairs(preset) do dlg:modify{id=id, visible=p} end
        for k, id in ipairs(upload) do dlg:modify{id=id, visible=u} end
        for k, id in ipairs(generative) do dlg:modify{id=id, visible=g} end
        if p and numColors == colorListP and mode then
            dlg:modify{id="colorWarning", visible = false}
            dlg:modify{id="colorWarning2", visible = false}
        elseif p and not mode then
            dlg:modify{id="colorPickerP", visible=mode}
            dlg:modify{id="addToShadesP", visible=mode}
            dlg:modify{id="shadesListP", visible=mode}
            dlg:modify{id="currentShades", visible=mode}
            dlg:modify{id="shadesLabelP", visible=mode}
            dlg:modify{id="shadesLabelP2", visible=mode}
            dlg:modify{id="colorWarning", visible=false}
            dlg:modify{id="colorWarning2", visible = false}
        end
        if u then
            if dlg.data.fromFile then
                swap_style(true)
            else
                swap_style(false)
            end
        end
    end

    local function get_image(pattern, colors)
        colors = colors or false
        local image
        if colors then
            local keyedColors = {}
            local symbols = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
            for i, v in ipairs(colors) do
                keyedColors[symbols:sub(i,i)] = v
            end
            local imageTable = pluginData.pattern.decode(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "PatternFiles", pattern.file), true)
            for k, _ in pairs(imageTable.header.colors) do
                imageTable.header.colors[k] = keyedColors[k]
            end
            image = pluginData.pattern.decode(imageTable)
        else
            image = pluginData.pattern.decode(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "PatternFiles", pattern.file))
        end
        return image
    end

    local function reset()
        pluginData.prefs.lastBounds = dlg.bounds
        pluginData.prefs.lastSelection = dlg.data.patternDropdown
        pluginData.prefs.lastColorCount = numColors
        pluginData.prefs.lastColors = dlg.data.currentShades
        pluginData.prefs.lastColorListP = colorListP
        swap_tabs("preset")
        dlg:close()
        show()
    end

    
    --Begin "Presets" tab.
    dlg:tab{
        id = "preset",
        text = "Presets",
        onclick = function() end
    }
    :separator{id="tabSeparatorP1"}
    :combobox{
        id="patternDropdown",
        label="Choose a preset: ",
        option=selection,
        options=get_pattern_names(),
        onchange=function() 
            local str
            local change = false
            for k in string.gmatch(dlg.data.patternDropdown, "([^%s]+)") do
                if patterns[k] and not change then
                    change = true
                    local temp = pluginData.pattern.decode(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "PatternFiles", patterns[k].file), true)
                    dlg:modify{id="currentShades", colors=temp.header.colors}
                    currentColors= pluginData.prefs.lastColors
                end
                str = k
            end
            numColors = tonumber(string.sub(str, 1, -2))
            pluginData.prefs.lastColorCount = numColors
            if numColors == #colorListP or (not mode) then
                dlg:modify{id="createFromPreset", enabled=true}
                dlg:modify{id="colorWarning", visible=false}
                dlg:modify{id="colorWarning2", visible=false}
            end
            if mode and numColors ~= #colorListP then
                dlg:modify{id="createFromPreset", enabled=false}
                dlg:modify{id="colorWarning", visible=true}
                dlg:modify{id="colorWarning2", visible=true}
            end
        end
    }
    :check{
        id="defaultColors",
        text="Use default colors?",
        selected=true,
        onclick=function()
            mode = (not mode)
            dlg:modify{id="colorPickerP", visible=mode}
            dlg:modify{id="addToShadesP", visible=mode}
            dlg:modify{id="currentShades", visible=mode}
            dlg:modify{id="shadesListP", visible=mode}
            dlg:modify{id="shadesLabelP", visible=mode}
            dlg:modify{id="shadesLabelP2", visible=mode}
            if not mode then
                dlg:modify{id="createFromPreset", enabled=true}
                dlg:modify{id="colorWarning", visible=false}
                dlg:modify{id="colorWarning2", visible=false}
            end
            if mode and numColors ~= #colorListP then
                dlg:modify{id="createFromPreset", enabled=false}
                dlg:modify{id="colorWarning", visible=true}
                dlg:modify{id="colorWarning2", visible=true}
            end
        end
    }
    :shades{
        id="currentShades",
        label="Current Shades: ",
        mode="pick",
        colors=currentColors,
        visible=false
    }
    :color{id="colorPickerP", visible = false}:newrow()
    :button{
        id="addToShadesP",
        text="Add to Shades",
        selected=false,
        focus=true,
        visible=false,
        onclick=function()
            table.insert(colorListP, dlg.data.colorPickerP)
            dlg:modify{id="shadesListP", colors=colorListP}
            if (numColors == #colorListP) then
                dlg:modify{id="createFromPreset", enabled=true}
                dlg:modify{id="colorWarning", visible=false}
                dlg:modify{id="colorWarning2", visible=false}
            else
                dlg:modify{id="createFromPreset", enabled=false}
                dlg:modify{id="colorWarning", visible=true}
                dlg:modify{id="colorWarning2", visible=true}
            end
        end
    }
    :shades{
        id="shadesListP", 
        label="New Shades: ", 
        mode="sort",
        visible=false,
        colors={},
        onclick=function(event)
            if event.button == MouseButton.LEFT then
                if dlg.data.shadesListP ~= colorListP then
                    colorListP = dlg.data.shadesListP
                    pluginData.prefs.lastColorListP = colorListP
                    if #colorListP ~= numColors then
                        dlg:modify{id="createFromPreset", enabled=false}
                        dlg:modify{id="colorWarning", visible=true}
                        dlg:modify{id="colorWarning2", visible=true}
                    end
                    if #colorListP == numColors then
                        dlg:modify{id="createFromPreset", enabled=true}
                        dlg:modify{id="colorWarning", visible=false}
                        dlg:modify{id="colorWarning2", visible=false}
                    end
                end
            end
        end
    }
    :label{
        id="shadesLabelP",
        visible=false,
        text="Drag a color off the bar to remove it from the shades collection,"
    }:newrow()
    :label{
        id="shadesLabelP2",
        visible=false,
        text="or drag it to another position to sort the colors."
    }
    :separator{id="blockSeparatorP1"}
    :label{
        id="colorWarning",
        text="Please ensure that you use the correct number of colors for",
        visible=false
    }:newrow()
    :label{
        id="colorWarning2",
        text="the preset, or use the default colors.",
        visible=false
    }
    :button{
        id="createFromPreset",
        text="Create",
        selected=false,
        focus=false,
        onclick=function()
            local name = dlg.data.patternDropdown:match("^(.+)%s[%(]")
            local selPattern = patterns[name]
            if not app.editor then
                app.command.NewFile{ui=false, width=selPattern.width, height=selPattern.height, colorMode=ColorMode.RGB, fromClipboard=false}
            end
            local sprite = app.sprite
            local layer = sprite:newLayer()
            layer.name = "Pattern"
            app.layer = layer
            local colors = false
            if mode then
                colors = colorListP
            end
            local image = get_image(selPattern, colors)
            local cel = sprite:newCel(layer, 1, image, {sprite.width/2,sprite.height/2})
            app.cel = cel
            app.refresh()
            dlg:close()
        end
    }
    :button{
        id="resetButton",
        text="Reset to Defaults",
        onclick=function()
            if create_confirm("Reset to defaults?") then
                set_default_patterns()
                save_patterns()
                reset()
            end
        end
    }

    --Begin "Upload" tab
    dlg:tab{
        id="upload",
        text="Upload/Create Pattern",
        onclick = function() end
    }
    :separator{id="tabSeparatorU1"}
    :radio{
        id="fromFile",
        text="Upload .ptn File",
        selected=true,
        onclick=function() 
            swap_style(true)
        end
    }
    :radio{
        id="fromSelection",
        text="Create .ptn from Selection",
        selected=false,
        onclick=function()
            swap_style(false)
        end
    }
    :separator{id="blockSeparatorU1"}
    :label{
        id="fileInfo",
        text="Uses .ptn files. Select the other radio button if you'd like to generate a .ptn file."
    }
    :file{
        id="file",
        open=true,
        entry=true,
        focus=true,
        filetypes={"ptn"}
    }
    :button{
        id="createFromFile",
        text="Create",
        selected=false,
        focus=true,
        onclick=function()
            local image = pluginData.pattern.decode(dlg.data.file, true)
            if not app.editor then
                app.command.NewFile{ui=false, height=image.header.height, width=image.header.width}
            end
            image = pluginData.pattern.decode(image)
            local layer = app.sprite:newLayer()
            layer.name = "PatternFile"
            app.layer=layer
            local cel = app.sprite:newCel(layer, 1, image, {app.sprite.width/2,app.sprite.height/2})
            app.refresh()
            dlg:close()
        end
    }
    :label{
        id="selectionInfo1",
        text="Generates and saves a new .ptn file with a given name from a selection."
    }:newrow()
    :label{
        id="selectionInfo2",
        text="Note: The file will be saved to the extension's PatternFiles folder, and will be added to Presets."
    }
    :file{
        id="save",
        save=true,
        entry=true,
        focus=true,
        filename="file.ptn",
        filetypes={"ptn"}
    }
    :button{
        id="createFromSelection",
        text="Create",
        selected=false,
        focus=true,
        onclick=function()
            if not app.sprite or not app.sprite.selection then
                print("No valid selection provided.")
            else
                app.command.NewSpriteFromSelection()
                local ptn = pluginData.pattern.encode(app.image)
                app.sprite:close()
                local fileName = dlg.data.save:match("PatternFiles[\\/](.+.ptn)$")
                local filePath = app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "PatternFiles" , fileName)
                local file,err = io.open(filePath, 'w')
                if file then
                    file:write(ptn)
                    file:close()
                    print("Success! File saved at " .. filePath)
                    ptn = pluginData.pattern.decode(filePath, true)
                    patterns[fileName:match("(.+).ptn")] = {name=fileName:match("(.+).ptn"), file=fileName, width=ptn.header.width, height=ptn.header.height, numColors=ptn.header.numColors}
                    save_patterns()
                    dlg:close()
                else
                    print("File write error: ", err)
                end
            end
        end
    }
    swap_style(true)

    --Begin Generative tab
    local colorList = {}
    dlg:tab{
        id="generative",
        text="Generate New Pattern",
        onclick = function() end
    }
    :separator{id="tabSeparatorG1"}
    :label{
        id="genSize",
        label="Image Size"
    }
    :number{id="width", label="Width, Height: ", decimals=0}
    :number{id="height", decimals=0}
    :separator{id="blockSeparatorG1"}
    :label{
        id="genColor",
        label="Color"
    }
    :color{id="colorPicker",}:newrow()
    :button{
        id="addToShades",
        text="Add to Shades",
        selected=false,
        focus=true,
        onclick=function()
            table.insert(colorList, dlg.data.colorPicker)
            dlg:modify{id="shadesList", colors=colorList}
        end
    }:newrow()
    :shades{
        id="shadesList", 
        label="Shades: ", 
        mode="sort", 
        colors={},
        onclick=function(event)
            if event.button == MouseButton.LEFT then
                if dlg.data.shadesList ~= colorList then
                    colorList = dlg.data.shadesList
                end
            end
        end
    }
    :separator{id="blockSeparatorG2"}
    :label{
        id="genPattern",
        label="Pattern"
    } --TODO: Define these selectors in generator.lua. Call generator to create patterns, then fill the colors into it
    :slider{
        id="blocky-wavy",
        label="Blocky to Wavy",
        min=-100,
        max=100,
        value=0
    }
    :slider{
        id="repetitive-unique",
        label="Pattern size",
        min=-100,
        max=100,
        value=0
    }
    :slider{
        id="simple-complex",
        label="Simple to Complex",
        min=-100,
        max=100,
        value=0
    }
    :slider{
        id="sparse-dense",
        label="Sparse to Dense",
        min=-100,
        max=100,
        value=0
    }
    :slider{
        id="colorSpread",
        label="Color mix",
        min=-100,
        max=100,
        value=0
    }
    :separator{id="blockSeparatorG3"}
    :button{
        id="infoButton",
        text="More information...",
        visible=true,
        onclick=function()
            print("For the shades:")
            print("Drag a color off the bar to remove it from the shades collection, or drag it to another position to sort the colors.")
            print("Pattern files generally sort colors from darkest on the left to brightest on the right as the standard.\n")
            print("For the sliders:")
            print("Blocky to wavy chooses how rigid the shapes are; how straight or how curvy they'll be.") --vertices vs edges, mathematically
            print("Pattern size chooses how often the pattern will occur, whether it repeats itself constantly with a small pattern, or occupies the entire image at once.")
            print("Simple to complex chooses how complex the pattern will be. Simpler patterns use simpler shapes and are easy to see the pattern in.")
            print("Sparse to dense chooses how much colored space there will be in the image. The background will always be white, so this chooses how much of the image will be the background.")
            print("Color mix determines how mixed each color in the palette will be. Low values will have a given colored pixel be near the same color, where high values will have a given colored pixel be near different colors.")
        end
    }
    :button{
        id="generateFromSettings",
        text="Generate new Pattern",
        visible=true,
        onclick=function()
            --TODO: Call generator.
        end
    }
    --TODO: Ask after the fact if you'd like to save the new pattern to a file, try again, or change settings. Move the window bounds to the side, then return them to default.

    dlg:endtabs{
        id="dialog1tabs",
        selected = "generative",
        onchange = function(ev)
            swap_tabs(ev.tab)
        end
    }
    swap_tabs("generative")


    if not pluginData.prefs.lastBounds then
        dlg:show{wait=false, bounds=Rectangle(app.window.width/4, app.window.height/4, app.window.width/3, app.window.height/2), autoscrollbars=true}
    else
        dlg:show{
            wait=false,
            bounds=pluginData.prefs.lastBounds,
            autoscrollbars=true
        }
    end
end

show()