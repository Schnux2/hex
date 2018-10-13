--Minetest 0.4 mod: hex, mostly by Schnux
--See README.txt and license.txt for licensing and other information.

hex={}

local default_prism={
	physical=true,
	is_visible=true,
	collisionbox = {-0.3, -0.5, -0.3, 0.3, 0.5, 0.3}, --otherwise, the player could not go through a hole in a wall made out of prisms
	selectionbox={-0.5,-0.5,-0.5,0.5,0.5,0.5},
	visual = "mesh",
	mesh = "hex_prism_2.obj",
	visual_size = {x=10, y=10},
	textures = {"hex_basalt.png"},
	hp_max=25,
	_groups={cracky=1},
	_mesh_offset_y=0, --with the slab, the mesh has to be 0.25 units below where the program thinks the middle of the object is. This doesn't have any effect in drawing, only in calculating the pointing positions.
	_height=1, --also only to calculate, not to draw
	_prism=true, --to identify them uniquely
}

function default_prism:on_punch(puncher, time_from_last_punch, tool_capabilities, direction, damage)
	if not puncher or not puncher:is_player() or not tool_capabilities or not tool_capabilities.groupcaps then
		return
	end
	local damages=false
	for k,v in pairs(self._groups) do
		if tool_capabilities.groupcaps[k] and tool_capabilities.groupcaps[k].times and tool_capabilities.groupcaps[k].times[v]~=nil then
			damages=true
			break
		end
	end
	if not damages then
		return
	end
	if minetest.is_protected(self.object:get_pos(),puncher:get_player_name()) then --untested
		minetest.record_protection_violation(self.object:get_pos(),puncher:get_player_name())
		return
	end
	local inv = puncher:get_inventory() --copied and adjusted from the "carts" mod from Minetest Game, probably by PilzAdam or SmallJoker
	if not (creative and creative.is_enabled_for
			and creative.is_enabled_for(puncher:get_player_name()))
			or not inv:contains_item("main", self.name) then
		local leftover = inv:add_item("main", self.name)
		if not leftover:is_empty() then
			minetest.add_item(self.object:get_pos(), leftover)
		end
	end
	self.object:remove()
	return --<\copied and adjusted>
end

function default_prism:_contains(pos)
	local sidelength=0.5
	local height=self._height
	local prism_pos=self.object:get_pos()
	prism_pos=vector.add(prism_pos,{x=0,y=self._mesh_offset_y,z=0})
	local pos_relative=vector.subtract(pos,prism_pos)
	if pos_relative.y>=-height/2 and pos_relative.y<=height/2 then --between sides 7 and 8
		local m_prism_side=math.tan(math.pi/6) --for some of the sides [rise of z(x)]
		if pos_relative.x*m_prism_side+sidelength>=pos_relative.z and
				pos_relative.x*m_prism_side-sidelength<=pos_relative.z and --between sides 4 and 1
				pos_relative.x*(-m_prism_side)+sidelength>=pos_relative.z and
				pos_relative.x*(-m_prism_side)-sidelength<=pos_relative.z and --between sides 3 and 6
				pos_relative.x>=-3^(1/2)*1/2*sidelength and
				pos_relative.x<=3^(1/2)*1/2*sidelength then --between sides 5 and 2
			return true
		end
	end
	return false
end

function default_prism:_overlaps_with(obj) --not sure if this always behaves right
	local selfpos=self.object:get_pos()
	local objpos=obj:get_pos()
	local luaentity=obj:get_luaentity()
	local vs={x=3^(1/2)/2,y=luaentity._height,z=1} --originally this was visual_size, now it is calculated differently
	local is_overlap=false
	
	if self:_contains(vector.add(objpos,{x=0,y=vs.y/2,z=-vs.z/2})) or --any of the vertices of the other prism --upper hexagon
			self:_contains(vector.add(objpos,{x=vs.x/2,y=vs.y/2,z=-vs.z/4})) or --are those values right?
			self:_contains(vector.add(objpos,{x=vs.x/2,y=vs.y/2,z=vs.z/4})) or
			self:_contains(vector.add(objpos,{x=0,y=vs.y/2,z=vs.z/2})) or
			self:_contains(vector.add(objpos,{x=-vs.x/2,y=vs.y/2,z=vs.z/4})) or
			self:_contains(vector.add(objpos,{x=-vs.x/2,y=vs.y/2,z=-vs.z/4})) or
			
			self:_contains(vector.add(objpos,{x=0,y=-vs.y/2,z=-vs.z/2})) or --lower hexagon
			self:_contains(vector.add(objpos,{x=vs.x/2,y=-vs.y/2,z=-vs.z/4})) or
			self:_contains(vector.add(objpos,{x=vs.x/2,y=-vs.y/2,z=vs.z/4})) or
			self:_contains(vector.add(objpos,{x=0,y=-vs.y/2,z=vs.z/2})) or
			self:_contains(vector.add(objpos,{x=-vs.x/2,y=-vs.y/2,z=vs.z/4})) or
			self:_contains(vector.add(objpos,{x=-vs.x/2,y=-vs.y/2,z=-vs.z/4})) then
		is_overlap=true
	end
	vs={x=3^(1/2)/2,y=self._height,z=1}
	if luaentity:_contains(vector.add(selfpos,{x=0,y=vs.y/2,z=-vs.z/2})) or --any of the vertices of this prism
			luaentity:_contains(vector.add(selfpos,{x=vs.x/2,y=vs.y/2,z=-vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=vs.x/2,y=vs.y/2,z=vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=0,y=vs.y/2,z=vs.z/2})) or
			luaentity:_contains(vector.add(selfpos,{x=-vs.x/2,y=vs.y/2,z=vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=-vs.x/2,y=vs.y/2,z=-vs.z/4})) or
			
			luaentity:_contains(vector.add(selfpos,{x=0,y=-vs.y/2,z=-vs.z/2})) or
			luaentity:_contains(vector.add(selfpos,{x=vs.x/2,y=-vs.y/2,z=-vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=vs.x/2,y=-vs.y/2,z=vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=0,y=-vs.y/2,z=vs.z/2})) or
			luaentity:_contains(vector.add(selfpos,{x=-vs.x/2,y=-vs.y/2,z=vs.z/4})) or
			luaentity:_contains(vector.add(selfpos,{x=-vs.x/2,y=-vs.y/2,z=-vs.z/4})) then
		is_overlap=true
	end
	local pdh=hex.pos_normal_to_hex(vector.subtract(objpos,selfpos)) --position difference (hex)
	if pdh.x>=0.499 and pdh.x<=0.501 then --rounding errors in pos_normal_to_hex, just a workaround
		pdh.x=0.5
	elseif pdh.x>=-0.501 and pdh.x<=-0.499 then
		pdh.x=-0.5
	elseif pdh.x>=0.999 and pdh.x<=1.001 then
		pdh.x=1
	elseif pdh.x>=-1.001 and pdh.x<=-0.999 then
		pdh.x=-1
	elseif pdh.x>=-0.001 and pdh.x<=0.001 then
		pdh.x=0
	end
	if pdh.z>=0.499 and pdh.z<=0.501 then
		pdh.z=0.5
	elseif pdh.z>=-0.501 and pdh.z<=-0.499 then
		pdh.z=-0.5
	elseif pdh.z>=-0.001 and pdh.z<=0.001 then
		pdh.z=0
	elseif pdh.z>=0.666 and pdh.z<=0.668 then
		pdh.z=0.667
	elseif pdh.z>=-0.668 and pdh.z<=-0.666 then
		pdh.z=-0.667
	end
	if pdh.y>=0.999 and pdh.y<=1.001 then
		pdh.y=1
	elseif pdh.y>=-1.001 and pdh.y<=-0.999 then
		pdh.y=-1
	elseif pdh.y>=-0.001 and pdh.y<=0.001 then
		pdh.y=0
	end
	if (pdh.x==0.5 and pdh.z==0.5) or --touching, not overlapping
			(pdh.x==-0.5 and pdh.z==0.5) or
			(pdh.x==0.5 and pdh.z==-0.5) or
			(pdh.x==-0.5 and pdh.z==-0.5) or --on sides 1,3,4,6 (not ordered like this)
			pdh.x==1 or
			pdh.x==-1 or --sides 2 and 5
			pdh.y==1 or
			pdh.y==-1 or --sides 7 and 8
			pdh.z==0.667 or
			pdh.z==-0.667 then --touching on only one edge
		is_overlap=false
	end
	return is_overlap
end

--[[
Point of intersection of one side and the line of sight (here yet with y instead of z) 
Schnittpunkt einer Seite und der Sichtlinie (hier noch mit y statt z)
m1*x+t1=m2*x+t2

t1 is defined as 0 (location of the player)
t1 sei definiert als 0 (Ort des Spielers)

y=m2*x+t2 shall be the equation of the side, y=m1*x+t1 the line of sight 
y=m2*x+t2 sei die Gleichung der Seite, y=m1*x+t1 die Sichtlinie

Distance from the beginning of the side to the center of the prism: 0.5 multiplied with the sidelength in x-direction, square root of 3 multiplied with the
sidelength in y-direction.
Abstand vom Anfang der Seite zum Mittelpunkt des Prismas: 0,5 mal Seitenlänge in x-Richtung und Wurzel aus 3 mal Seitenlänge durch 2 in y-Richtung

Distance from the center of the prism to the player is known (here x2 and y2, later dx and dz)
Abstand vom Mittelpunkt des Prismas zum Spieler ist bekannt (hier x2 und y2, später dx und dz)

(Movement of a line through origin with the same rise, so that it lies on the same location)
(Verschiebung einer Ursprungsgeraden mit gleicher Steigung, dass sie am gleichen Ort liegt.)

m2*x+t2=(x-x2+0,5*sidelength)*m2+y2-3^(1/2)*sidelength/2
=> t2 = (x-x2+0,5*sidelength)*m2+y2-3^(1/2)*sidelength/2 - m2*x
=> t2 = (-x2+0,5*sidelength)*m2+y2-3^(1/2)*sidelength/2

m2*x+t2=(x-x2+0,5*Seitenlänge)*m2+y2-3^(1/2)*Seitenlänge/2
=> t2 = (x-x2+0,5*Seitenlänge)*m2+y2-3^(1/2)*Seitenlänge/2 - m2*x
=> t2 = (-x2+0,5*Seitenlänge)*m2+y2-3^(1/2)*Seitenlänge/2

x=(t2-t1)/(m1-m2)=t2/(m1-m2) 
--]]

function default_prism:_get_fine_pointing_pos(player)
	local function crossing(m1y,m1z,m2z,p1,p3,p2_p3_arc_to_horizontal,mesh_offset_y,length,height) --only works for a prism (length is the radius of the cylinder around this prism)
	--m1y and m1z refer to a line, p1 to the origin of this line (the camera), m2z (m2y is not existent, the rectangular is perpendicular to 
	--the x-z-plane),length,height to a rectangle, p3 is a point(in the usecase the middle point of the prism)
	--mesh_offset_y is like defined in the default_prism table.
	--if m2z is "x=0", then the side of the prism is in the same direction than the z-axis, so the side can not be calculated as usual
		if type(m2z)=="number" then
			p3=vector.add(p3,{x=0,y=mesh_offset_y,z=0})
			local p3_p1_pos_diff=vector.subtract(p3,p1)
			local p2_relative=vector.add(p3_p1_pos_diff,{x=math.cos(p2_p3_arc_to_horizontal)*length,y=0,z=math.sin(p2_p3_arc_to_horizontal)*length}) --startpoint of a line parallel to the xz-plane of the side
			local p4_relative=vector.add(p3_p1_pos_diff,{x=math.cos(p2_p3_arc_to_horizontal+math.pi/3)*length,y=0,z=math.sin(p2_p3_arc_to_horizontal+math.pi/3)*length}) --endpoint of this side
			local t=(-p2_relative.x)*m2z+p2_relative.z --the side is a part of z=m2z*x+t --also relative (to p1, like many things here)
			if m1z-m2z==0 then --looking parallel to the side, can't give any good result
				return
			end
			
			local x_value_relative=t/(m1z-m2z)
			local z_value_relative=x_value_relative*m1z
			local y_value_relative=x_value_relative*m1y
			
			if (x_value_relative>=p2_relative.x and x_value_relative<=p4_relative.x and p2_relative.x<=p4_relative.x) or 
					(x_value_relative<=p2_relative.x and x_value_relative>=p4_relative.x and p2_relative.x>=p4_relative.x) then --x-coordinate is inside the rectangle
				if (z_value_relative>=p2_relative.z and z_value_relative<=p4_relative.z and p2_relative.z<=p4_relative.z) or 
						(z_value_relative<=p2_relative.z and z_value_relative>=p4_relative.z and p2_relative.z>=p4_relative.z) then --same with z
					if y_value_relative-p2_relative.y>=-0.5*height and y_value_relative-p2_relative.y<=0.5*height then
						return vector.add({x=x_value_relative,y=y_value_relative,z=z_value_relative},p1)
					end
				end
			end
		
		elseif type(m2z)=="string" and m2z=="x=0" then
			p3=vector.add(p3,{x=0,y=mesh_offset_y,z=0})
			local p3_p1_pos_diff=vector.subtract(p3,p1)
			local p2_relative=vector.add(p3_p1_pos_diff,{x=math.cos(p2_p3_arc_to_horizontal)*length,y=0,z=math.sin(p2_p3_arc_to_horizontal)*length}) --startpoint of a line parallel to the xz-plane of the side
			local p4_relative=vector.add(p3_p1_pos_diff,{x=math.cos(p2_p3_arc_to_horizontal+math.pi/3)*length,y=0,z=math.sin(p2_p3_arc_to_horizontal+math.pi/3)*length}) --endpoint of this side
			
			local x_value_relative=p2_relative.x --since p2,p4 and all other points of the side are on the yz-plane, the player's distance from any point on it is the same, so also from the point where he looks
			local z_value_relative=x_value_relative*m1z
			local y_value_relative=x_value_relative*m1y
			
			if (x_value_relative>=p2_relative.x and x_value_relative<=p4_relative.x and p2_relative.x<=p4_relative.x) or --always true?
					(x_value_relative<=p2_relative.x and x_value_relative>=p4_relative.x and p2_relative.x>=p4_relative.x) then --x-coordinate is inside the rectangle
				if (z_value_relative>=p2_relative.z and z_value_relative<=p4_relative.z and p2_relative.z<=p4_relative.z) or 
						(z_value_relative<=p2_relative.z and z_value_relative>=p4_relative.z and p2_relative.z>=p4_relative.z) then --same with z
					if y_value_relative-p2_relative.y>=-0.5*height and y_value_relative-p2_relative.y<=0.5*height then
						return vector.add({x=x_value_relative,y=y_value_relative,z=z_value_relative},p1)
					end
				end
			end
		end
	end
	
	local function crossing_hex(m1y,m1z,p1,p2,mesh_offset_y,radius) --only a hex in the xz-plane, edges on a circle around p2 with the given radius. m1y,m1z and p1 are like in the function crossing(...)
	--the hex has to have sides parallel to the z-axis (so with the equation x=c with c as a constant)
		p2=vector.add(p2,{x=0,y=mesh_offset_y,z=0})
		local p2_p1_pos_diff=vector.subtract(p2,p1)
		if m1y==0 then --looking parallel to the side
			return
		end
		--this time the values depends on the y-coordinate instead of the x-coordinate
		local m1x_dependent_of_y=1*1/m1y
		local m1z_dependent_of_y=m1z*1/m1y
		
		local y_value_relative=p2_p1_pos_diff.y
		local x_value_relative=y_value_relative*m1x_dependent_of_y
		local z_value_relative=y_value_relative*m1z_dependent_of_y
		
		if x_value_relative>=p2_p1_pos_diff.x-radius and x_value_relative<=p2_p1_pos_diff.x+radius then --sides 5 and 2
			local m2z=math.tan(math.pi/6) --the rise of two of the lines, for two others it is -m2z, like in the function crossing(...)
			if z_value_relative<=m2z*(x_value_relative-p2_p1_pos_diff.x) + p2_p1_pos_diff.z + radius and --side 4 --since those are lines in the xz-plane, they are defined as z(x) again
					z_value_relative>=m2z*(x_value_relative-p2_p1_pos_diff.x) + p2_p1_pos_diff.z - radius and --side 1
					z_value_relative<=-m2z*(x_value_relative-p2_p1_pos_diff.x) + p2_p1_pos_diff.z + radius and --side 3
					z_value_relative>=-m2z*(x_value_relative-p2_p1_pos_diff.x) + p2_p1_pos_diff.z - radius then --side 6 --inside all sides
				return vector.add({x=x_value_relative,y=y_value_relative,z=z_value_relative},p1)
			end
		end
	end
	
	local m_prism_side=math.tan(math.pi/6) --see the sides (and later the view line) as functions z(x) and y(x), this is the rise of z(x) of some of the sides
	local look_dir
	if player:get_look_dir().x~=0 then
		look_dir=vector.multiply(player:get_look_dir(),1/player:get_look_dir().x)
	else --not good like this, but otherwise the program could crash
		return {},0
	end
	local m_look_z=look_dir.z
	local m_look_y=look_dir.y
	local selfpos=self.object:get_pos()
	local playerpos=vector.add(player:get_pos(),{x=0,y=1.625,z=0}) --offset because the camera isn't exactly at the location which player:get_pos() returns
	local mesh_offset_y=self._mesh_offset_y
	
	local sidelength=0.5
	local height=self._height
	
	local ret --for returning: the line of sight will cross the prism on more than one side
	local side --for returning: an integer, starting from -x not clockwise, then the upper side, then the lower one
	
	local side_crossings={}
	--crossing(m1y,m1z,m2z,p1,p3,p2_p3_arc_to_horizontal,length,height)
	side_crossings[1]=crossing(m_look_y,m_look_z,m_prism_side,playerpos,selfpos,-math.pi/2,mesh_offset_y,sidelength,height)
	side_crossings[2]=crossing(m_look_y,m_look_z,"x=0",playerpos,selfpos,-math.pi/6,mesh_offset_y,sidelength,height)
	side_crossings[3]=crossing(m_look_y,m_look_z,-m_prism_side,playerpos,selfpos,math.pi/6,mesh_offset_y,sidelength,height)
	side_crossings[4]=crossing(m_look_y,m_look_z,m_prism_side,playerpos,selfpos,math.pi/2,mesh_offset_y,sidelength,height)
	side_crossings[5]=crossing(m_look_y,m_look_z,"x=0",playerpos,selfpos,math.pi*5/6,mesh_offset_y,sidelength,height)
	side_crossings[6]=crossing(m_look_y,m_look_z,-m_prism_side,playerpos,selfpos,-math.pi*5/6,mesh_offset_y,sidelength,height)
	side_crossings[7]=crossing_hex(m_look_y,m_look_z,playerpos,vector.add(selfpos,{x=0,y=0.5*height,z=0}),mesh_offset_y,sidelength)
	side_crossings[8]=crossing_hex(m_look_y,m_look_z,playerpos,vector.add(selfpos,{x=0,y=-0.5*height,z=0}),mesh_offset_y,sidelength)
	local sc_copy={}
	for k,v in pairs(side_crossings) do
		sc_copy[k]=v
	end
	local i=1
	while i<table.maxn(side_crossings) do
		if side_crossings[i] then
			i=i+1
		else
			for j=i+1,table.maxn(side_crossings) do
				side_crossings[j-1]=side_crossings[j]
			end
			side_crossings[table.maxn(side_crossings)]=nil
		end
	end
	table.sort(side_crossings,function(arg1,arg2)
		if math.abs(vector.length(vector.subtract(arg1,vector.add(player:get_pos(),{x=0,y=1.625,z=0}))))<math.abs(vector.length(vector.subtract(arg2,vector.add(player:get_pos(),{x=0,y=1.625,z=0})))) then
			return true
		else
			return false
		end
	end)
	ret=side_crossings[1]
	for k,v in pairs(sc_copy) do
		if v==side_crossings[1] then
			side=k
			break
		end
	end
	return ret,side
end

function default_prism:on_rightclick(clicker)
	local pointpos,side=self:_get_fine_pointing_pos(clicker)
	local selfpos=self.object:get_pos()
	local buildpos_hex=hex.pos_normal_to_hex(selfpos)
	local itemstack=clicker:get_wielded_item()
	if side and minetest.registered_craftitems[itemstack:get_name()] and minetest.registered_craftitems[itemstack:get_name()]._prism then
		if side==1 then
			buildpos_hex.x=buildpos_hex.x+0.5
			buildpos_hex.z=buildpos_hex.z-0.5
		elseif side==2 then
			buildpos_hex.x=buildpos_hex.x+1
		elseif side==3 then
			buildpos_hex.x=buildpos_hex.x+0.5
			buildpos_hex.z=buildpos_hex.z+0.5
		elseif side==4 then
			buildpos_hex.x=buildpos_hex.x-0.5
			buildpos_hex.z=buildpos_hex.z+0.5
		elseif side==5 then
			buildpos_hex.x=buildpos_hex.x-1
		elseif side==6 then
			buildpos_hex.x=buildpos_hex.x-0.5
			buildpos_hex.z=buildpos_hex.z-0.5
		elseif side==7 then
			buildpos_hex.y=buildpos_hex.y+1
		elseif side==8 then
			buildpos_hex.y=buildpos_hex.y-1
		end
		local buildpos=hex.pos_hex_to_normal(buildpos_hex)
		local temp_obj=minetest.add_entity(buildpos,"hex:prism_temporary")
		local overlaps=hex.check_for_overlaps(temp_obj)
		if overlaps then
			temp_obj:remove()
			clicker:set_wielded_item(itemstack)
			return
		end
		temp_obj:remove()
		if minetest.is_protected(buildpos,clicker:get_player_name()) then --untested
			minetest.record_protection_violation(buildpos,clicker:get_player_name())
			return
		end
		local obj=minetest.add_entity(buildpos,itemstack:get_name())
		if not (creative and creative.is_enabled_for --also from the carts mod, probably by PilzAdam or SmallJoker
				and creative.is_enabled_for(clicker:get_player_name())) then
			itemstack:take_item()
		end
		clicker:set_wielded_item(itemstack)
	end
end

function hex.register_prism(subname,prism_definition,craftitem_definition) --similar to stairs.register_stairs from the "stairs" mod of Minetest Game, probably by Kahrl or celeron55 (Perttu Ahola)
	local subname=subname or ""
	local prism_definition = prism_definition or {}
	local craftitem_definition = craftitem_definition or {}
	setmetatable(prism_definition,{__index=default_prism})
	minetest.register_entity(":hex:prism_"..subname,prism_definition)
	
	local default_craftitem={ --also copied and adjusted from the "carts" mod from Minetest Game, probably by PilzAdam or SmallJoker
	description="Basalt",
	inventory_image = "hex_basalt_inventory.png",
	wield_image = "hex_basalt_wield.png",
	on_place = function(itemstack, placer, pointed_thing)
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local udef = minetest.registered_nodes[node.name]
		if udef and udef.on_rightclick then
			return udef.on_rightclick(under, node, placer, itemstack,
				pointed_thing) or itemstack
		end
		if not pointed_thing.type == "node" then
			return
		end
		--should not be possible if there is already a prism, even if not exactly
		local buildpos=pointed_thing.above
		local temp_obj=minetest.add_entity(buildpos, "hex:prism_temporary")
		local overlaps=hex.check_for_overlaps(temp_obj)
		if overlaps then
			temp_obj:remove()
			return itemstack
		end
		temp_obj:remove()
		if minetest.is_protected(buildpos,placer:get_player_name()) then --untested
			minetest.record_protection_violation(buildpos,placer:get_player_name())
			return itemstack
		end
		local obj=minetest.add_entity(buildpos,"hex:prism_"..subname)
		if not (creative and creative.is_enabled_for
				and creative.is_enabled_for(placer:get_player_name())) then
			itemstack:take_item()
		end
		return itemstack --<\copied and adjusted>
	end,
	_prism=true,
	}
	for k,v in pairs(default_craftitem) do --does for some reason not work with metatables
		if craftitem_definition[k]==nil then
			craftitem_definition[k]=v
		end
	end
	minetest.register_craftitem(":hex:prism_"..subname, craftitem_definition)
end

function hex.check_for_overlaps(obj) --whether obj overlaps with any other prism --is always checked with a temporary object with a fixed size, but this should not be any problem since the radius can not be changed anyway and a slab should still "overlap" with other prisms the normal way, everything different would probably be confusing.
	if not obj:get_luaentity()._prism then
		return
	end
	local pos=obj:get_pos()
	local others=minetest.get_objects_inside_radius(pos,2)
	local prisms={}
	for k,v in pairs(others) do
		if v:get_luaentity() and v:get_luaentity()._prism and not v:get_luaentity()._temporary then --checking _temporary to make sure it does not check overlapping with itself
			table.insert(prisms,v)
		end
	end
	local overlaps=false
	for k,prism in ipairs(prisms) do
		if not overlaps then
			overlaps=obj:get_luaentity():_overlaps_with(prism)
		end
		if not overlaps and obj:get_pos().x==prism:get_pos().x and obj:get_pos().y==prism:get_pos().y and obj:get_pos().z==prism:get_pos().z then
			overlaps=true
		end
	end
	return overlaps
end

function hex.pos_normal_to_hex(pos) --not actually needed, but sometimes used for convenience (since the prisms may have not-whole number coordinates)
	local hex_pos={}
	hex_pos.y=pos.y
	hex_pos.x=pos.x*2/(3^(1/2))
	hex_pos.z=pos.z*2/3
	return hex_pos
end

function hex.pos_hex_to_normal(hex_pos)
	local pos={}
	pos.y=hex_pos.y
	pos.x=hex_pos.x*(3^(1/2))/2
	pos.z=hex_pos.z*3/2
	return pos
end

function hex.vector_round(v) --rounds x and z to whole numbers and whole numbers+0.5 instead of only whole numbers
	local vcopy={}
	for k,v in pairs(v) do
		vcopy[k]=v
	end
	v.x=math.floor(v.x*2+0.5)/2
	v.y=math.floor(v.y+0.5) --y-coordinates are normally rounded
	v.z=math.floor(v.z*2+0.5)/2
	if (v.x==math.floor(v.x) and v.z==math.floor(v.z)) or (v.x~=math.floor(v.x) and v.z~=math.floor(v.z)) then --not all of the coordinates should be possible, e.g (0,0.5) is wrong because there is already a prism on (0,0)
		return v
	else
		local d=vector.subtract(v,vcopy)
		if math.abs(d.x)>math.abs(d.z) then --determine whether it is more sensible to adapt the y- or z- coordinate
			if d.x>0 then --determine what is the right direction to adapt
				v.x=v.x-0.5
			else
				v.x=v.x+0.5
			end
		else
			if d.z>0 then
				v.z=v.z-0.5
			else
				v.z=v.z+0.5
			end
		end
		return v
	end
end

hex.register_prism("temporary",
	{_temporary=true},
	{groups={not_in_creative_inventory=1}})

dofile(minetest.get_modpath(minetest.get_current_modname()).."\\test.lua")
