function ContraptionResizer.ResizeContraptionByEnt( rootEntity, scalePhysMul, scaleVisuMul )

	local entities = constraint.GetAllConstrainedEntities( rootEntity )

	for _, ent in pairs( entities ) do

		local scalePhys, scaleVisu = CollisionResizer.GetSize( ent )
		if not scalePhys then return end

		CollisionResizer.SetSize( ent, scalePhys * scalePhysMul, scaleVisu * scaleVisuMul )

	end

end