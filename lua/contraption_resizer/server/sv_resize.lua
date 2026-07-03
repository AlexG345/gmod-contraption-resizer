function ContraptionResizer.ResizeContraptionByEnt( rootEntity, scalePhysMul, scaleVisuMul, massScale )

	local entities		= {}
	local constrs		= {}
	duplicator.GetAllConstrainedEntitiesAndConstraints( rootEntity, entities, constrs )

	local rootPhys = rootEntity:GetPhysicsObject()
	if not rootPhys then return end

	local allEnts	= {}
	local foundEnts	= {}

	for _, ent in pairs( entities ) do
		allEnts[ent] = {}
		foundEnts[ent] = true
	end

	local addedChild = {}

	local function addChildren( ent, children )

		if addedChild[ent] or not isfunction( ent.GetChildren ) then return end
		addedChild[ent] = true

		for child in pairs( ent:GetChildren() ) do
			if foundEnts[child] then continue end
			foundEnts[child] = true
			children[child] = {}
			addChildren( child, children[child] )
		end
	end

	for ent, children in pairs( allEnts ) do
		addChildren( ent, children )
	end

	local foundConstrs	= {}

	for _, constr in pairs( constrs ) do

		constr = constr.Constraint
		if foundConstrs[constr] then continue end
		foundConstrs[constr] = constr

		if not ( constr.LPos1 and constr.LPos2 and constr.Ent1 and constr.Ent2 ) then continue end

		local pos1 = constr.Ent1:LocalToWorld( constr.LPos1 )
		local pos2 = constr.Ent2:LocalToWorld( constr.LPos2 )
		local direction = pos2 - pos1
		if direction == vector_origin then
			direction = Vector( 1, 1, 1 )
		end
		direction:Normalize()
		local localDirection = rootPhys:WorldToLocalVector( direction )

		lengthMul = ( localDirection * scalePhysMul ):Length()
		-- print(lengthMul)

		for _, name in ipairs( { "length", "addlength", "Length1", "Length2" } ) do
			if constr[name] then
				-- print(name, constr[name], "->", constr[name] * lengthMul)
				constr[name] = constr[name] * lengthMul
			end
		end

	end

	local function resize( ent )
		local scalePhys, scaleVisu = CollisionResizer.GetScale( ent )
		if not scalePhys then return end

		local parent = isfunction( ent.GetParent ) and IsValid( ent:GetParent() ) and ent:GetParent()

		if ent ~= rootEntity then
			relativeEnt = parent or rootEntity
			local pos = relativeEnt:WorldToLocal( ent:GetPos() )
			pos:Mul( scalePhysMul )
			if not parent then pos = relativeEnt:LocalToWorld( pos ) end
			ent:SetPos( pos )
		end

		local phys					= ent:GetPhysicsObject()
		local improvedWeightExists	= istable( improvedweight )

		if improvedWeightExists and phys:IsValid() then
			improvedweight.SetModifiedWeight( ent, phys:GetMass() * massScale )
		end

		CollisionResizer.SetScale(
			ent,
			scalePhys * scalePhysMul,
			scaleVisu * scaleVisuMul,
			false,
			false,
			true
		)

	end

	local function resizeRecur( data )
		for ent, children in pairs( data ) do
			resize( ent )
			resizeRecur( children )
		end
	end

	resizeRecur( allEnts )

end