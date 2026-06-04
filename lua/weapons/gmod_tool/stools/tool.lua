local mode = TOOL.Mode


if SERVER then

	local flags = bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED )

	-- Create server console variables here.

	flags = nil

else

	TOOL.Category	= "Construction"
	TOOL.Name		= "Contraption Resizer"

	TOOL.Information = {
		{ name = "left" }
		{ name = "right" }
	}

	TOOL.ClientConVar = {
		--["width"] = 1
	}

	local t = "tool." .. mode .. "."
	local function l( ... )
		local a = { ... }
		if #a == 2 then table.insert( a, 1, t ) elseif #a < 2 then return end
		print( a[1], a[2], a[3] )
		language.Add( a[1] .. a[2], a[3] )
	end

	l( "listname", TOOL.Name )
	l( "name", TOOL.Name )
	l( "desc", "Easily resize any contraption." )
	l( "0" )
	l( "left", "Resize" )
	l( "right", "Inverse resize" )

	t, l = nil, nil

end


local conVars = CLIENT and TOOL:BuildConVarList() or nil

function TOOL.BuildCPanel( cPanel )

	local t = "tool." .. mode .. "."
	local function l( ... )
		local a = { ... }
		if #a == 1 then table.insert( a, 1, t )
		elseif #a < 1 then return end
		return language.GetPhrase( a[1] .. a[2] )
	end

	cPanel:Help( l( "desc" ) )

	-- cPanel:ToolPresets( mode, conVars )

	t, l = nil, nil

end