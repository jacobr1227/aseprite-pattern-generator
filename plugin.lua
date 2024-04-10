function init(plugin)
    print("Initializing pattern generator...")
    local debug = false
    if plugin.preferences == nil then
        plugin.preferences = {}
    end
    local data = {
        prefs = plugin.preferences,
        json = dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "json.lua")),
        logger = {
            Log = function(msg) if(debug == true) then print("LOG: " .. msg) end end;
            Error = function(msg)  if(debug == true) then print("ERROR: " .. msg) end end;
            LineBreak = function() if(debug == true) then print("--------------------------------------------------------------------------------------") end end;
        },
        pattern = dofile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator", "ptn.lua"))
    }

    local function AddCommand(id, title, group, file, loc)
        plugin:newCommand{
            id=id,
            title=title,
            group=group,
            onclick=function()
                loadfile(app.fs.joinPath(app.fs.userConfigPath, "extensions", "Pattern_Generator",loc, file))(data)
            end
        }
    end
    
    AddCommand("Pattern_Generator", "Pattern Generator", "file_new", "dialogs.lua", "")
    print("Pattern Generator initialized.")
end

function exit(plugin)
    print("Aseprite is closing Pattern Generator.")
end