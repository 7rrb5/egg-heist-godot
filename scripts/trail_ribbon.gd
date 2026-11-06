extends MeshInstance3D

@export var width := 0.75
@export var max_points := 34
@export var min_distance := 0.32
var trail_color := Color(0.2, 0.65, 1.0, 0.72)
var points: Array[Vector3] = []
var immediate := ImmediateMesh.new()
var mat := StandardMaterial3D.new()
var enabled_trail := false

func _ready() -> void:
	mesh = immediate
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = trail_color
	mat.emission_energy_multiplier = 2.4
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func set_level(level: int) -> void:
	enabled_trail = level > 0
	visible = enabled_trail
	var colors := [
		Color(0.7,0.7,0.7,0.55), Color(0.25,1.0,0.35,0.62), Color(0.15,0.55,1.0,0.68),
		Color(0.65,0.2,1.0,0.72), Color(1.0,0.25,0.75,0.76), Color(1.0,0.72,0.16,0.78),
		Color(0.1,1.0,0.95,0.8), Color(0.9,0.15,1.0,0.82), Color(1.0,0.25,0.25,0.84),
		Color(0.8,0.9,1.0,0.86), Color(0.35,0.65,1.0,0.9)
	]
	if level > 0:
		trail_color = colors[clampi(level - 1, 0, colors.size() - 1)]
		mat.emission = trail_color
		width = 0.65 + level * 0.055

func _process(_delta: float) -> void:
	if not enabled_trail or get_parent() == null:
		immediate.clear_surfaces()
		return
	var p := get_parent().global_position + Vector3(0, 0.18, 0)
	if points.is_empty() or points[0].distance_to(p) >= min_distance:
		points.push_front(p)
		if points.size() > max_points:
			points.pop_back()
	_rebuild()

func _rebuild() -> void:
	immediate.clear_surfaces()
	if points.size() < 2:
		return
	immediate.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, mat)
	for i in range(points.size()):
		var p := points[i]
		var tangent: Vector3
		if i == 0:
			tangent = points[0] - points[1]
		else:
			tangent = points[i - 1] - points[i]
		tangent.y = 0
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()
		var side := Vector3.UP.cross(tangent).normalized() * width
		var alpha := 1.0 - float(i) / float(max(1, points.size() - 1))
		var c := trail_color
		c.a *= alpha * 0.92
		immediate.surface_set_color(c)
		immediate.surface_add_vertex(to_local(p + side))
		immediate.surface_set_color(c)
		immediate.surface_add_vertex(to_local(p - side))
	immediate.surface_end()
