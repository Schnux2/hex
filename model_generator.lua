--Minetest 0.4 mod: hex, mostly by Schnux
--See README.txt and license.txt for licensing and other information.

--Trying to generate a model with "triangular pixels" (hex_prism_2.obj). This is never actually called from the mod and intended for a standalone lua interpreter.
--This script was written for a single purpose, but it looks actually horrible. Do not trust any of the values used here. Do not trust that it works.

--Minetest doesn't seem to care about the given normals (except that faces have to have one)! Instead, it seems to care about the order of 
--the vertices on a given face to determine the "direction" of the face. As far as I understand it, this is quite weird. 
--anticlockwise => visible from below, clockwise =>visible from above?

--Those paths probably have to be changed.
local objfile=io.open("C:/minetest-0.4.16-win64/mods/hex/models/hex_prism_2.obj","w")
local mtlfile=io.open("C:/minetest-0.4.16-win64/mods/hex/models/hex_prism_2.mtl","w")

local vertices={} --strings, so no references, but values
local texture_vertices={} --strings
local faces={} --strings
local accuracy=6 --number of figures behind the comma

local texture_size_u=64 --uv-coordinates instead of xy
local texture_size_v=64

local hex_size_u=16 --on the texture
local hex_size_v=16

local height=1
local offset_y=0 --see _mesh_offset_y in the definition of the prism in init.lua

function table_find(t,value)
	for k,v in pairs(t) do
		if v==value then
			return k
		end
	end
	return nil
end

function generate_tri_pixel(x,y,z,left,vfb,normal,radius) --only in a parallel plane to the xz-plane 
	--left is a boolean, how it is oriented (in the xz-plane), maybe it has to be inverted.
	--vfb means "visible from below".
	local face=""
	local function pixel_pos_to_abs(pos_uv)
		pos_uv.u=pos_uv.u/texture_size_u
		pos_uv.v=pos_uv.v/texture_size_v
		return pos_uv
	end
	local arcs={}
	if left then
		if vfb then
			arcs={-math.pi/3,math.pi/3,math.pi,math.pi} --the last one is the same one as the one before, because it has to be stretched on the texture into a pixel which is quadratic
		else
			arcs={math.pi,math.pi/3,-math.pi/3,-math.pi/3}
		end
	else
		if vfb then
			arcs={0,math.pi*2/3,-math.pi*2/3,-math.pi*2/3}
		else
			arcs={-math.pi*2/3,math.pi*2/3,0,0}
		end
	end
	
	for i,arc in ipairs(arcs) do
		local x_offset=math.cos(arc)*radius
		local z_offset=math.sin(arc)*radius
		local v_str=string.format("%."..accuracy.."f",x+x_offset).." "..string.format("%."..accuracy.."f",y).." "..string.format("%."..accuracy.."f",z+z_offset)
		local u_row=math.floor(x/1.5*2*2*2*hex_size_u/2+0.5)
		u_row=u_row/2
		local v_column=math.floor(z/3^(1/2)*2*2*hex_size_v+0.5)
		local u_offset=(y-offset_y)/height*(hex_size_v+1)
		local vt_pixel={u=u_row+0.5+u_offset,v=v_column+0.5+texture_size_v/2}
		--The +0.5 so that it is the center of a pixel, not its (probably) left-down corner
			--y is the height coordinate, so the texture vertices whose vertices are lower have to be separated by some amount y*hex_size_x from the texture vertices whose vertices are more above
		local vt_offset_pixel={u=0,v=0}
		
		--stretching the triangle onto a rectangle (a pixel)
		if left then
			if vfb then
				if arc/math.pi*3==-1 then
					vt_offset_pixel={u=-0.5,v=-0.5}
				elseif arc/math.pi*3==1 then
					vt_offset_pixel={u=0.5,v=-0.5}
				elseif arc/math.pi*3==3 then
					if i==3 then
						vt_offset_pixel={u=0.5,v=0.5}
					elseif i==4 then
						vt_offset_pixel={u=-0.5,v=0.5}
					end
				end
			else
				if arc/math.pi*3==3 then
					vt_offset_pixel={u=-0.5,v=-0.5}
				elseif arc/math.pi*3==1 then
					vt_offset_pixel={u=0.5,v=-0.5}
				elseif arc/math.pi*3==-1 then
					if i==3 then
						vt_offset_pixel={u=0.5,v=0.5}
					elseif i==4 then
						vt_offset_pixel={u=-0.5,v=0.5}
					end
				end
			end
		else
			if vfb then
				if arc/math.pi*3==0 then
					vt_offset_pixel={u=-0.5,v=-0.5}
				elseif arc/math.pi*3==2 then
					vt_offset_pixel={u=0.5,v=-0.5}
				elseif arc/math.pi*3==-2 then
					if i==3 then
						vt_offset_pixel={u=0.5,v=0.5}
					elseif i==4 then
						vt_offset_pixel={u=-0.5,v=0.5}
					end
				end
			else
				if arc/math.pi*3==-2 then
					vt_offset_pixel={u=-0.5,v=-0.5}
				elseif arc/math.pi*3==2 then
					vt_offset_pixel={u=0.5,v=-0.5}
				elseif arc/math.pi*3==0 then
					if i==3 then
						vt_offset_pixel={u=0.5,v=0.5}
					elseif i==4 then
						vt_offset_pixel={u=-0.5,v=0.5}
					end
				end
			end
		end
		
		local vt=pixel_pos_to_abs({u=vt_pixel.u+vt_offset_pixel.u+hex_size_u,v=vt_pixel.v+vt_offset_pixel.v+hex_size_v/2})
		local vt_str=string.format("%."..accuracy.."f",vt.u).." "..string.format("%."..accuracy.."f",vt.v)
		
		local v_i
		if i~=4 then --one face may not use one vertex twice (at least in blender - maybe this has to be removed), so there is this workaround
			v_i=table_find(vertices,v_str)
		end
		if not v_i then
			table.insert(vertices,v_str)
			v_i=table.maxn(vertices)
		end
		
		local vt_i=table_find(texture_vertices,vt_str)
		if not vt_i then
			table.insert(texture_vertices,vt_str)
			vt_i=table.maxn(texture_vertices)
		end
		
		face=face..v_i.."/"..vt_i.."/"..normal.." "
	end
	table.insert(faces,face)
end

--has maybe some issues!
local sidelength=1/hex_size_v
local tri_height=3/4/hex_size_u
local x0=-tri_height*hex_size_u/2+tri_height*2/3
for x=x0,0,tri_height do
	local m_prism_side=3^(1/2)/3 --tan(30°)
	local z0=x*-m_prism_side-0.5+sidelength/2 -- +sidelength/2 to determine the center of a triangle, not the point on the edge of the surrounding prism
	for z=z0+1/hex_size_v*3^(1/2)/2,-z0,1/hex_size_v*3^(1/2)/2 do
		for h=-height/2,height/2,height do --y-value which corresponds to the actual height of the triangle (This is not obvious in such a badly written program!)
			local vfb=false
			local normal=5
			if h<0 then
				vfb=true
				normal=8
			end
			local h1=h+offset_y
			local left=true
			generate_tri_pixel(x,h1,z,left,vfb,normal,1/hex_size_u/2)
			if -x>1/hex_size_u/4 then --actually no idea why, if this is not there, there are overlaps in the middle of the prism
				generate_tri_pixel(x+3/4/hex_size_u*2/3,h1,z,not left,vfb,normal,1/hex_size_u/2) --3/4/hex_size_u may not be substituted by tri_height?
			end
			if x==x0 and z+1/hex_size_v*3^(1/2)/2<-z0 then --first row, has to be filled
				generate_tri_pixel(x-tri_height/3,h1,z+(1/hex_size_v*3^(1/2)/2)/2,not left,vfb,normal,1/hex_size_u/2)
			end
			--mirror on the z-axis
			generate_tri_pixel(-x,h1,z,not left,vfb,normal,1/hex_size_u/2)
			if -x>1/hex_size_u/4 then --same condition as above
				generate_tri_pixel(-x-3/4/hex_size_u*2/3,h1,z,left,vfb,normal,1/hex_size_u/2)
			end
			if x==x0 and z+1/hex_size_v*3^(1/2)/2<-z0 then --last row, has to be filled
				generate_tri_pixel(-x+tri_height/3,h1,z+(1/hex_size_v*3^(1/2)/2)/2,left,vfb,normal,1/hex_size_u/2)
			end
		end
	end
end 
--This produces something with the wrong radius, so it needs to be adjusted.

--This is how one should not program things.
function string.split(str,delim)
	local delim=delim or "%s"
	local ret={}
	while str:len()>0 do
		local s,e=str:len(),str:len()
		if str:find(delim) then
			s,e=str:find(delim)
		end
		table.insert(ret,str:sub(1,s))
		str=str:sub(e+1,-1)
	end
	return ret
end
local function vertex_multiply(v,s) --only in the x- and z-direction!
	v.x=v.x*s
	v.z=v.z*s
	return v
end
local vertex1=string.split(vertices[1])
local factor=-(3^(1/2)/2/2)/(vertex1[1]-tri_height) --vertex1 is not on the (left) edge of the prism => adjusting with -tri_height
for i,vertex in ipairs(vertices) do
	local v=vertex:split() --returns a table with [1],[2] and [3], not x,y and z
	v.x,v.y,v.z=v[1],v[2],v[3]
	v=vertex_multiply(v,factor)
	vertex=string.format("%."..accuracy.."f",v.x).." "..string.format("%."..accuracy.."f",v.y).." "..string.format("%."..accuracy.."f",v.z)
	vertices[i]=vertex
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

objfile:write([[mtllib hex_prism_2.mtl
o Prism

]])
--vertices:
for i,vertex in ipairs(vertices) do
	objfile:write("v "..vertex.."\n")
end
objfile:write("\n")

--texture vertices:
for i,texture_vertex in ipairs(texture_vertices) do
	objfile:write("vt "..texture_vertex.."\n")
end
objfile:write("\n")

--normals, copied form hex_prism_1.obj:
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
for i,face in ipairs(faces) do
	objfile:write("f "..face.."\n")
end
objfile:write("\n")

--The big surrounding prism
local fbv=table.maxn(vertices)+1 --first "big" vertex
local fbvt=table.maxn(texture_vertices)+1
objfile:write("v 0.000000 "..string.format("%."..accuracy.."f",-height/2+offset_y).." -0.500000\n"..
"v 0.000000 "..string.format("%."..accuracy.."f",height/2+offset_y).." -0.500000\n"..
"v 0.433013 "..string.format("%."..accuracy.."f",-height/2+offset_y).." -0.250000\n"..
"v 0.433013 "..string.format("%."..accuracy.."f",height/2+offset_y).." -0.250000\n"..
"v 0.433013 "..string.format("%."..accuracy.."f",-height/2+offset_y).." 0.250000\n"..
"v 0.433013 "..string.format("%."..accuracy.."f",height/2+offset_y).." 0.250000\n"..
"v -0.000000 "..string.format("%."..accuracy.."f",-height/2+offset_y).." 0.500000\n"..
"v -0.000000 "..string.format("%."..accuracy.."f",height/2+offset_y).." 0.500000\n"..
"v -0.433013 "..string.format("%."..accuracy.."f",-height/2+offset_y).." 0.250000\n"..
"v -0.433013 "..string.format("%."..accuracy.."f",height/2+offset_y).." 0.250000\n"..
"v -0.433013 "..string.format("%."..accuracy.."f",-height/2+offset_y).." -0.250000\n"..
"v -0.433013 "..string.format("%."..accuracy.."f",height/2+offset_y).." -0.250000\n\n"..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*3/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*3/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*4/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*4/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*5/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*5/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*6/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*6/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*0/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*0/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*1/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*1/texture_size_u,16/texture_size_v*height)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*2/texture_size_u,0)..
string.format("vt %."..accuracy.."f %."..accuracy.."f\n",8*2/texture_size_u,16/texture_size_v*height).."\n")

objfile:write("f "..fbv.."/"..fbvt.."/1 "..fbv+1 .."/"..fbvt+1 .."/1 "..fbv+3 .."/"..fbvt+2 .."/1 "..fbv+2 .."/"..fbvt+3 .."/1\n") --just copied and adjusted from hex_prism_1.obj
objfile:write("f "..fbv+2 .."/"..fbvt+3 .."/2 "..fbv+3 .."/"..fbvt+2 .."/2 "..fbv+5 .."/"..fbvt+4 .."/2 "..fbv+4 .."/"..fbvt+5 .."/2\n")
objfile:write("f "..fbv+4 .."/"..fbvt+5 .."/3 "..fbv+5 .."/"..fbvt+4 .."/3 "..fbv+7 .."/"..fbvt+6 .."/3 "..fbv+6 .."/"..fbvt+7 .."/3\n")
objfile:write("f "..fbv+6 .."/"..fbvt+8 .."/4 "..fbv+7 .."/"..fbvt+9 .."/4 "..fbv+9 .."/"..fbvt+10 .."/4 "..fbv+8 .."/"..fbvt+11 .."/4\n") --this is the side which is the leftmost in the uv-map

objfile:write("f "..fbv+8 .."/"..fbvt+11 .."/6 "..fbv+9 .."/"..fbvt+10 .."/6 "..fbv+11 .."/"..fbvt+12 .."/6 "..fbv+10 .."/"..fbvt+13 .."/6\n")
objfile:write("f "..fbv+10 .."/"..fbvt+13 .."/7 "..fbv+11 .."/"..fbvt+12 .."/7 "..fbv+1 .."/"..fbvt+1 .."/7 "..fbv.."/"..fbvt.."/7\n")

mtlfile:close()
objfile:close()

print("Done!")
