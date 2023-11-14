# Parse data type into dictionary
func parse_vector2(data) -> Dictionary:
	var dict = {}
	dict["x"] = data.x
	dict["y"] = data.y
	return dict
	
func parse_vector3(data) -> Dictionary:
	var dict = {}
	dict["x"] = data.x
	dict["y"] = data.y
	dict["z"] = data.z
	return dict
	
func parse_vector4(data) -> Dictionary:
	var dict = {}
	dict["x"] = data.x
	dict["y"] = data.y
	dict["z"] = data.z
	dict["w"] = data.w
	return dict
	
func parse_color(data: Color) -> Dictionary:
	var dict = {}
	dict["r"] = data.r
	dict["g"] = data.g
	dict["b"] = data.b
	dict["a"] = data.a
	return dict
