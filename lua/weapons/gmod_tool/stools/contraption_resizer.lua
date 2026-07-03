local mode = TOOL.Mode


if SERVER then

	local flags = bit.bor( FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED )

	-- Create server console variables here.

	flags = nil

else

	TOOL.Category	= "Construction"
	TOOL.Name		= "Contraption Resizer"

	TOOL.Information = {
		{ name = "left" },
		{ name = "right" },
	}

	TOOL.ClientConVar["phys_x"]				= "1.0"
	TOOL.ClientConVar["phys_y"]				= "1.0"
	TOOL.ClientConVar["phys_z"]				= "1.0"
	TOOL.ClientConVar["phys_xyz"]			= "1.0"
	TOOL.ClientConVar["use_phys_for_visu"]	= "1"
	TOOL.ClientConVar["mass_scale"]			= "1.0"
	TOOL.ClientConVar["visu_x"]				= "1.0"
	TOOL.ClientConVar["visu_y"]				= "1.0"
	TOOL.ClientConVar["visu_z"]				= "1.0"
	TOOL.ClientConVar["visu_xyz"]			= "1.0"

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
	l( "phys_xyz", "Physical XYZ Scale" )
	l( "phys_x", "Physical X Scale" )
	l( "phys_y", "Physical Y Scale" )
	l( "phys_z", "Physical Z Scale" )
	l( "use_phys_for_visu", "Scale Visual with Physical" )
	l( "use_phys_for_visu.help", "Use the above values to scale visually." )
	l( "mass_scale", "Mass scaling" )
	l( "visu_xyz", "Visual XYZ Scale" )
	l( "visu_x", "Visual X Scale" )
	l( "visu_y", "Visual Y Scale" )
	l( "visu_z", "Visual Z Scale" )

	t, l = nil, nil

end


function TOOL:LeftClick( trace )

	local ent = trace.Entity
	if not CollisionResizer.SupportsPhysicalData( ent ) then return false end

	if CLIENT then return true end

	local scalePhys = self:GetClientVector( "phys" )
	local scaleVisu = self:GetClientBool( "use_phys_for_visu" ) and scalePhys or self:GetClientVector( "visu" )

	ContraptionResizer.ResizeContraptionByEnt(
		ent,
		scalePhys,
		scaleVisu,
		self:GetClientNumber( "mass_scale" )
	)

	return true

end


function TOOL:RightClick( trace )

	local ent = trace.Entity
	if not CollisionResizer.SupportsPhysicalData( ent ) then return false end

	if CLIENT then return true end

	local scalePhys = self:GetClientVector( "phys" )
	local scaleVisu = self:GetClientBool( "use_phys_for_visu" ) and Vector( scalePhys ) or self:GetClientVector( "visu" )

	for _, vec in ipairs( { scalePhys, scaleVisu } ) do
		vec:Set( Vector( 1 / vec.x, 1 / vec.y, 1 / vec.z ) )
	end

	ContraptionResizer.ResizeContraptionByEnt(
		ent,
		scalePhys,
		scaleVisu,
		1 / self:GetClientNumber( "mass_scale" )
	)

	return true

end


if SERVER then

	function TOOL:GetClientVector( prefix )

		return Vector(
			self:GetClientNumber( prefix .. "_x" ),
			self:GetClientNumber( prefix .. "_y" ),
			self:GetClientNumber( prefix .. "_z" )
		)

	end

end


local conVars = CLIENT and TOOL:BuildConVarList() or nil

function TOOL.BuildCPanel( cPanel )

	local token = "tool." .. mode .. "."
	local function l( ... )
		local a = { ... }
		if #a == 1 then table.insert( a, 1, token )
		elseif #a < 1 then return end
		return language.GetPhrase( a[1] .. a[2] )
	end

	cPanel:Help( l( "desc" ) )

	-- cPanel:ToolPresets( mode, conVars )

	local function createScaleSliders( scaleType )

		local scaleSliders = {}

		-- HACK: convar is set so that going past the max still updates the other sliders...
		local t = scaleType .. "_xyz"
		local XYZNumSlider = cPanel:NumSlider( l( t ), mode .. "_" .. t, 0.1, 10 )

			local oOVC = XYZNumSlider.Scratch.OnValueChanged
			function XYZNumSlider.Scratch:OnValueChanged( value )

				for _, slider in pairs( scaleSliders ) do
					if slider:IsEditing() then return end
				end
				-- if not XYZNumSlider:HasFocus() then return end
				for _, slider in ipairs( scaleSliders ) do
					slider.Scratch:SetValue( value )
					slider:ValueChanged( value )
				end

				oOVC( self, value )
			end

		for i, axis in ipairs( { "x", "y", "z" } ) do
			t = scaleType .. "_" .. axis
			local slider = cPanel:NumSlider( l( t ), mode .. "_" .. t, 0.1, 10 )
			scaleSliders[i] = slider
		end

		return scaleSliders

	end

	local physScaleSliders = createScaleSliders( "phys" )

	local massScaleSlider = cPanel:NumSlider( l( "mass_scale" ), mode .. "_mass_scale", 0.01, 1000 )

	local comboBox = vgui.Create( "DComboBox", cPanel )
	cPanel:AddItem( comboBox )
	comboBox:SetSize( 100, 20 )
	comboBox:SetValue( "Scale calculations" )
	comboBox:AddChoice( "Volume", function( x, y, z ) return x * y * z end )
	comboBox:AddChoice( "Surface", function( x, y, z ) return ( x * y + x * z + y * z ) / 3 end )
	comboBox:AddChoice( "Linear", function( x, y, z ) return ( x + y + z ) / 3 end )
	function comboBox:OnSelect( index, value, data )
		local x, y, z = physScaleSliders[1]:GetValue(), physScaleSliders[2]:GetValue(), physScaleSliders[3]:GetValue()
		massScaleSlider.Scratch:SetValue( data( x, y, z ) )
	end

	cPanel:CheckBox( l( "use_phys_for_visu" ), mode .. "_use_phys_for_visu" )

	createScaleSliders( "visu" )

	token, l = nil, nil

end