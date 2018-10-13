--Minetest 0.4 mod: hex, mostly by Schnux
--See README.txt and license.txt for licensing and other information.

hex.register_prism("basalt",{},{})
hex.register_prism("basalt_slab",{
	visual_size={x=10,y=10}, --prism definition
	mesh="hex_prism_slab_2.obj",
	collisionbox={-0.3,-0.5,-0.3,0.3,0,0.3},
	selectionbox={-0.5,-0.5,-0.5,0.5,0,0.5},
	_mesh_offset_y=-0.25,
	_height=0.5,
},{description="Basalt slab"}) --craftitem definition