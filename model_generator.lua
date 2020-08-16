--Minetest 0.4 mod: hex,  mostly by Schnux
--See README.txt and license.txt for licensing and other information.

--[[This script generates a model with "triangular pixels" (hex_prism_2.obj).
This is never actually called from the mod and intended for a standalone lua interpreter.--]]

--[[
Minetest doesn't seem to care about the given normals (except that faces have to have one)! Instead,  it seems to care about the order of 
the vertices on a given face to determine the "direction" of the face. As far as I understand it,  this is quite weird. 
anticlockwise  = > visible from below,  clockwise  = > visible from above?--]]

local objfile = io.open("./models/hex_prism_2.obj", "w")
local mtlfile = io.open("./models/hex_prism_2.mtl", "w")

local vertices = {} --strings,  so no references,  but values
local texture_vertices = {} --strings
local faces = {} --strings
local accuracy = 6 --number of figures behind the comma

local hex_size = 16 --size of the hexagon on the uv-map (in u-direction),  in pixels. This also adjusts the sizes of the other faces on the uv-map.

local height = 1 --height of the prism
local offset = {x = 0, y = 0, z = 0} --offset of the prism
local radius = 0.5 --radius of the prism (the circle which encompasses the hexagons)

local texture_size_u = hex_size/2*6 --size of the uv-map,  in pixels
local texture_size_v = hex_size*height + hex_size*2 - 1

function table.find(t, value)
	--returns the key where the value can be found
	for k, v in pairs(t) do
		if v == value then
			return k
		end
	end
	return nil
end

function generate_tri_pixel(x, y, z, left, vfb, normal, tri_radius)
	--[[
	Generates a triangular face on a parallel plane to the xz-plane which is uv-mapped to a pixel.
	left is a boolean,  how it is oriented (in the xz-plane).
	vfb means "visible from below" and therefore determines (see the comments at the beginning of the script)
	the order of the vertices in the face definition.
	normal is an index.
	tri_radius is the radius of the circle which encompasses the triangle.--]]
	
	local face = ""
	
	local function pixel_pos_to_abs(pos_uv) --the coordinates which are written to the files are in [0;1],  the pixel coordinates aren't.
		pos_uv.u = pos_uv.u/texture_size_u
		pos_uv.v = pos_uv.v/texture_size_v
		return pos_uv
	end
	
	local arcs = {} --to determine the vertices of the face
	if left then
		if vfb then
			arcs = {-math.pi/3, math.pi/3, math.pi, math.pi} --the last one is the same one as the one before,  because it has to be stretched on the texture into a pixel which is quadratic
		else
			arcs = {math.pi, math.pi/3, -math.pi/3, -math.pi/3}
		end
	else
		if vfb then
			arcs = {0, math.pi*2/3, -math.pi*2/3, -math.pi*2/3}
		else
			arcs = {-math.pi*2/3, math.pi*2/3, 0, 0}
		end
	end
	
	for i, arc in ipairs(arcs) do --generating the vertices and texture vertices
		local x_offset = math.cos(arc)*tri_radius --offsets of the vertex relative to the given (x, y, z) position
		local z_offset = math.sin(arc)*tri_radius
		
		local v_str = string.format("%."..accuracy.."f", x+x_offset).." "..string.format("%."..accuracy.."f", y).." "..string.format("%."..accuracy.."f", z+z_offset) --vertex string
		
		local u_column = math.floor((x-offset.x)/(radius*3^(1/2))*hex_size+0.5)
		if left then
			u_column = u_column-1
		end
		local v_row = math.floor((z-offset.z)/radius*hex_size+0.5)
		
		local u_offset = math.ceil((y-offset.y)/height*hex_size)
		--the texture vertices whose vertices are lower have to be separated by some amount (u_offset) from the texture vertices whose vertices are more above
		local vt_pixel = {u = u_column+0.5+u_offset, v = v_row-0.5 + hex_size*height}
		--The +0.5 so that it is the center of a pixel,  not its left-down corner
		
		local vt_offset_pixel = {u = 0, v = 0} --offset of the texture vertex relative to the pixel position
		if left then
			if vfb then
				if arc/math.pi*3 == -1 then
					vt_offset_pixel = {u = -0.5, v = -0.5}
				elseif arc/math.pi*3 == 1 then
					vt_offset_pixel = {u = 0.5, v = -0.5}
				elseif arc/math.pi*3 == 3 then
					if i == 3 then
						vt_offset_pixel = {u = 0.5, v = 0.5}
					elseif i == 4 then
						vt_offset_pixel = {u = -0.5, v = 0.5}
					end
				end
			else
				if arc/math.pi*3 == 3 then
					vt_offset_pixel = {u = -0.5, v = -0.5}
				elseif arc/math.pi*3 == 1 then
					vt_offset_pixel = {u = 0.5, v = -0.5}
				elseif arc/math.pi*3 == -1 then
					if i == 3 then
						vt_offset_pixel = {u = 0.5, v = 0.5}
					elseif i == 4 then
						vt_offset_pixel = {u = -0.5, v = 0.5}
					end
				end
			end
		else
			if vfb then
				if arc/math.pi*3 == 0 then
					vt_offset_pixel = {u = -0.5, v = -0.5}
				elseif arc/math.pi*3 == 2 then
					vt_offset_pixel = {u = 0.5, v = -0.5}
				elseif arc/math.pi*3 == -2 then
					if i == 3 then
						vt_offset_pixel = {u = 0.5, v = 0.5}
					elseif i == 4 then
						vt_offset_pixel = {u = -0.5, v = 0.5}
					end
				end
			else
				if arc/math.pi*3 == -2 then
					vt_offset_pixel = {u = -0.5, v = -0.5}
				elseif arc/math.pi*3 == 2 then
					vt_offset_pixel = {u = 0.5, v = -0.5}
				elseif arc/math.pi*3 == 0 then
					if i == 3 then
						vt_offset_pixel = {u = 0.5, v = 0.5}
					elseif i == 4 then
						vt_offset_pixel = {u = -0.5, v = 0.5}
					end
				end
			end
		end
		
		local vt = pixel_pos_to_abs({u = vt_pixel.u+vt_offset_pixel.u+hex_size,  v = vt_pixel.v+vt_offset_pixel.v+hex_size})
		local vt_str = string.format("%."..accuracy.."f", vt.u).." "..string.format("%."..accuracy.."f", vt.v) --texture vertex string
		
		local v_i --index of the vertex
		if i~= 4 then --one face may not use one vertex twice (at least in blender),  so there is this workaround
			v_i = table.find(vertices, v_str)
		end
		if not v_i then
			table.insert(vertices, v_str)
			v_i = table.maxn(vertices)
		end
		
		local vt_i = table.find(texture_vertices, vt_str) --index of the texture vertex
		if not vt_i then
			table.insert(texture_vertices, vt_str)
			vt_i = table.maxn(texture_vertices)
		end
		
		face = face..string.format("%d", v_i).."/"..string.format("%d", vt_i).."/"..string.format("%d", normal).." "
	end
	table.insert(faces, face)
end

--[[
generating the upper and lower hexagon which consist of a lot of small triangles
iterating over x- and z-coordinates to the middle of the hexagon,  mirroring on the z-axis--]]

local tri_sidelength = 2*radius/hex_size --sidelength of the small triangles (the "triangular pixels")
local tri_height = tri_sidelength*3^(1/2)/2 --height (in z-direction) of the small triangles

local x0 = -radius*3^(1/2)/2 + tri_height*2/3
for x = x0, 0, tri_height do
	local m_prism_side = 3^(1/2)/3 --tan(30°),  rise of the side of the prism,  to determine the start value of z from x via a function z(x)
	local z0 = (x-2/3*tri_height)*-m_prism_side-radius -- x-2/3*tri_height instead of just x to determine the position of the center of the triangle,  not the point on the edge of the surrounding prism
	for z = z0, -z0, tri_sidelength do
		for h = -height/2, height/2, height do --y of the triangle (this loop is only called twice,  once for the upper side,  once for the lower one)
			local vfb = false
			local normal = 5
			if h<0 then
				vfb = true
				normal = 8
			end
			local h1 = h+offset.y
			local z1 = z+offset.z
			local left = true
			
			--generating two triangles formed like <|>
			generate_tri_pixel(x+offset.x, h1, z1, left, vfb, normal, tri_height*2/3)
			if -x>tri_height then --with this if-clause,  overlaps in the middle of the prism are prevented
				generate_tri_pixel(x+offset.x+tri_height*2/3, h1, z1, not left, vfb, normal, tri_height*2/3)
			end
			
			--mirror on the z-axis,  generating two triangles formed like |><|
			generate_tri_pixel(-x+offset.x, h1, z1, not left, vfb, normal, tri_height*2/3)
			if -x>tri_height then --same condition as above
				generate_tri_pixel(-x+offset.x-tri_height*2/3, h1, z1, left, vfb, normal, tri_height*2/3)
			end
			
			if x<x0+tri_height/2 and z+tri_sidelength/2<-z0 then --special treatment of the first and last columns
				--for some reasons,  a simple x == x0 does not always work to determine whether it is the first or last column
				generate_tri_pixel(x+offset.x-tri_height/3, h1, z1+tri_sidelength/2, not left, vfb, normal, tri_height*2/3)
				generate_tri_pixel(-x+offset.x+tri_height/3, h1, z1+tri_sidelength/2, left, vfb, normal, tri_height*2/3)
			end
		end
	end
end


--actual writing to the files:
--material:
mtlfile:write([[newmtl Material
Ns 96.078431
Ka 1.000000 1.000000 1.000000
Kd 0.640000 0.640000 0.640000
Ks 0.500000 0.500000 0.500000
Ke 0.000000 0.000000 0.000000
Ni 1.000000
d 1.000000
illum 2]])--whatever this means

--object file:
objfile:write([[mtllib hex_prism_2.mtl
o Prism

]])
--vertices:
for i, vertex in ipairs(vertices) do
	objfile:write("v "..vertex.."\n")
end
objfile:write("\n")

--texture vertices:
for i, texture_vertex in ipairs(texture_vertices) do
	objfile:write("vt "..texture_vertex.."\n")
end
objfile:write("\n")

--normals,  copied form hex_prism_1.obj:
objfile:write([[vn 0.5000 0.0000 -0.8660
vn 1.0000 0.0000 0.0000
vn 0.5000 0.0000 0.8660
vn -0.5000 0.0000 0.8660
vn 0.0000 1.0000 0.0000
vn -1.0000 0.0000 0.0000
vn -0.5000 0.0000 -0.8660
vn 0.0000 -1.0000 0.0000]])
objfile:write("\n")

objfile:write([[usemtl Material
s off

]])

--faces:
for i, face in ipairs(faces) do
	objfile:write("f "..face.."\n")
end
objfile:write("\n")

--The sides of the big surrounding prism
local fbv = table.maxn(vertices)+1 --first "big" vertex
local fbvt = table.maxn(texture_vertices)+1 --first "big" texture vertex
objfile:write(
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 0+offset.x, -height/2+offset.y, -radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 0+offset.x, height/2+offset.y, -radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 3^(1/2)/2*radius+offset.x, -height/2+offset.y, -0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 3^(1/2)/2*radius+offset.x, height/2+offset.y, -0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 3^(1/2)/2*radius+offset.x, -height/2+offset.y, 0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 3^(1/2)/2*radius+offset.x, height/2+offset.y, 0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 0+offset.x, -height/2+offset.y, radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", 0+offset.x, height/2+offset.y, radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", -3^(1/2)/2*radius+offset.x, -height/2+offset.y, 0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", -3^(1/2)/2*radius+offset.x, height/2+offset.y, 0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", -3^(1/2)/2*radius+offset.x, -height/2+offset.y, -0.5*radius+offset.z)..
string.format("v %."..accuracy.."f %."..accuracy.."f %."..accuracy.."f\n", -3^(1/2)/2*radius+offset.x, height/2+offset.y, -0.5*radius+offset.z)..

string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*3/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*3/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*4/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*4/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*5/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*5/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*6/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*6/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*0/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*0/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*1/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*1/texture_size_u, hex_size/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*2/texture_size_u, 0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n", hex_size/2*2/texture_size_u, hex_size/texture_size_v*height).."\n")

objfile:write(string.format("f %d/%d/1 %d/%d/1 %d/%d/1 %d/%d/1\n",  fbv, fbvt,  fbv+1, fbvt+1,  fbv+3, fbvt+2,  fbv+2, fbvt+3)) --just copied and adjusted from hex_prism_1.obj
objfile:write(string.format("f %d/%d/2 %d/%d/2 %d/%d/2 %d/%d/2\n",  fbv+2, fbvt+3,  fbv+3, fbvt+2,  fbv+5, fbvt+4,  fbv+4, fbvt+5))
objfile:write(string.format("f %d/%d/3 %d/%d/3 %d/%d/3 %d/%d/3\n",  fbv+4, fbvt+5,  fbv+5, fbvt+4,  fbv+7, fbvt+6,  fbv+6, fbvt+7))
objfile:write(string.format("f %d/%d/4 %d/%d/4 %d/%d/4 %d/%d/4\n",  fbv+6, fbvt+8,  fbv+7, fbvt+9,  fbv+9, fbvt+10,  fbv+8, fbvt+11)) --this is the side which is the leftmost in the uv-map
objfile:write(string.format("f %d/%d/6 %d/%d/6 %d/%d/6 %d/%d/6\n",  fbv+8, fbvt+11,  fbv+9, fbvt+10,  fbv+11, fbvt+12,  fbv+10, fbvt+13))
objfile:write(string.format("f %d/%d/7 %d/%d/7 %d/%d/7 %d/%d/7\n",  fbv+10, fbvt+13,  fbv+11, fbvt+12,  fbv+1, fbvt+1,  fbv, fbvt))

mtlfile:close()
objfile:close()

print("Done!")