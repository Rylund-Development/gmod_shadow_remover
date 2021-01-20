
--[[-----------------------------------------------------------------------------------

		Tool Creator - SnowredWolf | STEAM_0:0:41063225 | https://SnowredWolf.net
		Tool Purpose - Remove shadows from props

-------------------------------------------------------------------------------------]]


--[[-------------------------------------------------------------------------
		Default tool stuff
---------------------------------------------------------------------------]]
	TOOL.Category = "Render"
	TOOL.Author = "SnowredWolf"
	TOOL.Name = "#tool.shadowremover.name"
	TOOL.Desc = "#tool.shadowremover.desc"
	TOOL.ConfigName = ""

	TOOL.ClientConVar[ "valueInterval" ] = 10

--[[-------------------------------------------------------------------------
		Variables and networking
---------------------------------------------------------------------------]]
	shadowremovertool = {}
	shadowremovertool.proplist = shadowremovertool.proplist or {}
	if SERVER then
		util.AddNetworkString("RemovePropShadow")
		util.AddNetworkString("AddPropShadow")
		util.AddNetworkString("RemoveShadowsWhenJoining")
	end


--[[-------------------------------------------------------------------------
		Setting up the tool options
---------------------------------------------------------------------------]]
	if CLIENT then
		TOOL.Information = {
			{ name = "info", stage = 1 },
			{ name = "left" },
			{ name = "right" },
			{ name = "reload"},
			{ name = "reload_left", icon2 = "gui/lmb.png"},
			{ name = "reload_right", icon2 = "gui/rmb.png"}
		}

		language.Add("tool.shadowremover.name", "Shadow Remover")
		language.Add("tool.shadowremover.left", "Remove shadows")
		language.Add("tool.shadowremover.right", "Add shadows")
		language.Add("tool.shadowremover.reload", "Reset brightness")
		language.Add("tool.shadowremover.reload_left", "Make the prop darker" )
		language.Add("tool.shadowremover.reload_right", "Make the prop brighter" )
		language.Add("tool.shadowremover.desc", "Used to disable map shadows from props, making you able to avoid pitch black props!")
	end

--[[-------------------------------------------------------------------------
		Handle what happens when using left click
---------------------------------------------------------------------------]]
	function TOOL:LeftClick(trace)
		local ent = trace.Entity

		if IsEntity(ent) and (ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_ragdoll") then
			if CLIENT then return true end
			if not self:GetOwner():KeyDown(IN_RELOAD) then
				shadowremovertool.removepropshadow(ent)
			else
				shadowremovertool.makedarker(self, ent)
			end

			return true
		end

		return false
	end

--[[-------------------------------------------------------------------------
		Handle what happens when using right click
---------------------------------------------------------------------------]]
	function TOOL:RightClick(trace)
		local ent = trace.Entity
		if IsEntity(ent) and (ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_ragdoll") then
			if CLIENT then return true end
			if not self:GetOwner():KeyDown(IN_RELOAD) then
				shadowremovertool.addpropshadows(ent)
			else
				shadowremovertool.makebrighter(self, ent)
			end
			return true
		end

		return false
	end


--[[-------------------------------------------------------------------------
		Handle what happens when pressing reload
---------------------------------------------------------------------------]]
	function TOOL:Reload(trace)
		trace.ent:SetColor(ent.originalcolor)
	end

--[[-------------------------------------------------------------------------
		Serverside functions to handle shadows
---------------------------------------------------------------------------]]
	if SERVER then
		local colnew
		local h, s, v
		local entcolor

		function shadowremovertool.removepropshadow(ent)
			shadowremovertool.proplist[ent] = true
			ent.originalcolor = ent:GetColor()
			_, _, ent.v = ColorToHSV(ent.originalcolor)
			net.Start("RemovePropShadow")
				net.WriteEntity(ent)
			net.Broadcast()

			return true
		end

		function shadowremovertool.addpropshadows(ent)
			if not shadowremovertool.proplist[ent] then return false end
			shadowremovertool.proplist[ent] = nil
			ent:SetColor(ent.originalcolor)
			ent.originalcolor = nil

			net.Start("AddPropShadow")
				net.WriteEntity(ent)
			net.Broadcast()
		end

		function shadowremovertool.makedarker(self, ent)
			if not shadowremovertool.proplist[ent] then return false end
			if ent.v <= 0.1 then return end
			h, s, _ = ColorToHSV(ent.originalcolor)
			local newValue = ent.v - self:GetClientNumber('valueInterval', 10) / 100
			ent.v = 0.1 < newValue and newValue or 0.1
			ent:SetColor(HSVToColor(h, s, ent.v))
		end

		function shadowremovertool.makebrighter(self, ent)
			if not shadowremovertool.proplist[ent] then return false end
			h, s, _ = ColorToHSV(ent.originalcolor)
			if ent.v >= 0.99 then return end

			local newValue = ent.v + self:GetClientNumber('valueInterval', 10) / 100

			ent.v = 0.99 > newValue and newValue or 0.99

			ent:SetColor(HSVToColor(h, s, ent.v))
		end

		function shadowremovertool.loadpropshadowsonjoin(ply)
			net.Start("RemoveShadowsWhenJoining")
				net.WriteTable(shadowremovertool.proplist)
			net.Send(ply)
		end

		hook.Add("PlayerInitialSpawn", "RemoveShadowsWhenInitialSpawn", function(ply)
			timer.Simple(5, function()
				shadowremovertool.loadpropshadowsonjoin(ply)
			end)
		end)
	end

--[[-------------------------------------------------------------------------
		Build the tool panel
---------------------------------------------------------------------------]]
	function TOOL.BuildCPanel(panel)
		panel:Help("Darkness interval in %")

		panel:NumSlider("Percentage: ",
			"shadowremover_valueInterval",
			"1",
			"100"
		)
	end

--[[-------------------------------------------------------------------------
		Clientside networking
---------------------------------------------------------------------------]]
	net.Receive("RemovePropShadow", function()
		local ent = net.ReadEntity()
		ent.RenderOverride = function(self) render.SuppressEngineLighting(true) self:DrawModel() render.SuppressEngineLighting(false) end
	end)

	net.Receive("AddPropShadow", function()
		local ent = net.ReadEntity()
		ent.RenderOverride = function(self) self:DrawModel() end
	end)

	net.Receive("RemoveShadowsWhenJoining", function()
		local proplist = net.ReadTable()
		for ent, _ in pairs(proplist) do
			ent.RenderOverride = function(self) render.SuppressEngineLighting(true) self:DrawModel() render.SuppressEngineLighting(false) end
		end
	end)