extends CharacterBody3D

var game: Node
var model := Node3D.new()
var yaw_pivot := Node3D.new()
var pitch_pivot := Node3D.new()
var spring := SpringArm3D.new()
var camera := Camera3D.new()
var carry_anchor := Node3D.new()
var trail: MeshInstance3D
var limbs: Array[Node3D] = []
var phase := 0.0
var gravity := 22.0
var mouse_sense := 0.0026
var carrying_egg: Node3D
var training := false
var training_transform := Transform3D.IDENTITY
var training_accum := 0.0

# Mobile touch state
var left_touch := -1
var right_touch := -1
var left_origin := Vector2.ZERO
var left_current := Vector2.ZERO
var mobile_move := Vector2.ZERO
var touch_enabled := false

func _ready() -> void:
	game = get_parent()
	_build_collision()
	_build_model()
	_build_camera()
	_build_trail()
	carry_anchor.position = Vector3(0, 2.1, -1.2)
	add_child(carry_anchor)
	touch_enabled = OS.has_feature("web_android") or OS.has_feature("web_ios") or OS.has_feature("mobile")
	if not touch_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_collision() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new(); cap.radius = 0.55; cap.height = 1.85
	cs.shape = cap; cs.position.y = 1.0
	add_child(cs)

func _mat(c: Color, rough := 0.7, emission := Color.BLACK) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough
	if emission != Color.BLACK:
		m.emission_enabled = true; m.emission = emission; m.emission_energy_multiplier = 2.0
	return m

func _add_box(parent: Node3D, pos: Vector3, size_v: Vector3, c: Color) -> MeshInstance3D:
	var b := BoxMesh.new(); b.size = size_v
	var n := MeshInstance3D.new(); n.mesh = b; n.position = pos; n.material_override = _mat(c); parent.add_child(n); return n

func _add_sphere(parent: Node3D, pos: Vector3, scale_v: Vector3, c: Color) -> MeshInstance3D:
	var s := SphereMesh.new(); s.radial_segments = 16; s.rings = 9
	var n := MeshInstance3D.new(); n.mesh = s; n.position = pos; n.scale = scale_v; n.material_override = _mat(c); parent.add_child(n); return n

func _make_limb(pos: Vector3, size_v: Vector3, c: Color) -> Node3D:
	var p := Node3D.new(); p.position = pos; model.add_child(p)
	var n := _add_box(p, Vector3(0,-size_v.y*0.46,0), size_v, c)
	limbs.append(p); return p

func _build_model() -> void:
	model.name = "Avatar"
	add_child(model)
	# Higher-detail Roblox-like original avatar: shoes, limbs, layered shirt, head, hair.
	_add_box(model, Vector3(0,1.6,0), Vector3(1.15,1.45,0.7), Color(0.07,0.12,0.2))
	_add_box(model, Vector3(0,1.65,-0.38), Vector3(0.82,0.8,0.06), Color(0.05,0.55,0.95))
	_add_sphere(model, Vector3(0,2.8,0), Vector3(0.66,0.72,0.64), Color(0.92,0.73,0.56))
	_add_sphere(model, Vector3(0,3.15,0.02), Vector3(0.72,0.25,0.7), Color(0.16,0.08,0.04))
	for x in [-0.22,0.22]: _add_sphere(model, Vector3(x,2.86,-0.57), Vector3(0.06,0.07,0.035), Color(0.05,0.05,0.06))
	var la := _make_limb(Vector3(-0.78,2.25,0), Vector3(0.4,1.4,0.45), Color(0.92,0.73,0.56))
	var ra := _make_limb(Vector3(0.78,2.25,0), Vector3(0.4,1.4,0.45), Color(0.92,0.73,0.56))
	var ll := _make_limb(Vector3(-0.34,1.0,0), Vector3(0.52,1.65,0.58), Color(0.08,0.09,0.11))
	var rl := _make_limb(Vector3(0.34,1.0,0), Vector3(0.52,1.65,0.58), Color(0.08,0.09,0.11))
	for x in [-0.34,0.34]: _add_box(model, Vector3(x,0.1,-0.12), Vector3(0.62,0.32,0.9), Color(0.9,0.93,0.98))

func _build_camera() -> void:
	yaw_pivot.position = Vector3(0,2.25,0)
	add_child(yaw_pivot)
	yaw_pivot.add_child(pitch_pivot)
	pitch_pivot.rotation.x = deg_to_rad(-16)
	pitch_pivot.add_child(spring)
	spring.spring_length = 8.5
	spring.margin = 0.25
	spring.collision_mask = 1
	spring.add_child(camera)
	camera.current = true
	camera.fov = 68.0

func _build_trail() -> void:
	trail = MeshInstance3D.new()
	trail.set_script(load("res://scripts/trail_ribbon.gd"))
	add_child(trail)
	trail.call_deferred("set_level", int(Save.data.trail_level))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(Vector2(event.relative.x, event.relative.y) * mouse_sense)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not touch_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE and not touch_enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if game:
			game.try_interact(self)
	elif event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(e: InputEventScreenTouch) -> void:
	var size := get_viewport().get_visible_rect().size
	if e.pressed:
		if e.position.x < size.x * 0.48 and left_touch == -1:
			left_touch = e.index; left_origin = e.position; left_current = e.position
		elif right_touch == -1:
			right_touch = e.index
	else:
		if e.index == left_touch:
			left_touch = -1; mobile_move = Vector2.ZERO
		if e.index == right_touch:
			right_touch = -1

func _handle_drag(e: InputEventScreenDrag) -> void:
	if e.index == left_touch:
		left_current = e.position
		mobile_move = (left_current - left_origin) / 82.0
		if mobile_move.length() > 1.0: mobile_move = mobile_move.normalized()
	elif e.index == right_touch:
		_look(e.relative * 0.0045)

func _look(v: Vector2) -> void:
	yaw_pivot.rotate_y(-v.x)
	pitch_pivot.rotation.x = clamp(pitch_pivot.rotation.x - v.y, deg_to_rad(-62), deg_to_rad(28))

func _physics_process(delta: float) -> void:
	phase += delta
	if training:
		global_transform.origin = training_transform.origin
		rotation.y = training_transform.basis.get_euler().y
		velocity = Vector3.ZERO
		training_accum += delta
		Save.data.speed = float(Save.data.speed) + delta * (28.0 * pow(1.78, int(Save.data.treadmill_level)-1))
		if training_accum >= 1.0:
			training_accum = 0.0; Save.save_data()
		_animate(true, 1.0)
		return

	if not is_on_floor(): velocity.y -= gravity * delta
	var input_vec := Vector2(
		(1.0 if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT) else 0.0),
		(1.0 if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP) else 0.0)
	)
	if mobile_move.length() > 0.05:
		input_vec = mobile_move
	var basis := yaw_pivot.global_basis
	var forward := -basis.z; forward.y = 0; forward = forward.normalized()
	var right := basis.x; right.y = 0; right = right.normalized()
	var dir := (right * input_vec.x + forward * -input_vec.y)
	if dir.length() > 1.0: dir = dir.normalized()
	var speed_stat: float = maxf(1.0, float(Save.data.speed))
	var trail_mult: float = 1.0 + float(int(Save.data.trail_level)) * 0.08
	var move_speed: float = clampf(6.8 + log(speed_stat + 1.0) / log(10.0) * 1.55, 7.0, 23.0) * trail_mult
	var accel: float = 34.0
	velocity.x = move_toward(velocity.x, dir.x * move_speed, accel * delta)
	velocity.z = move_toward(velocity.z, dir.z * move_speed, accel * delta)
	move_and_slide()
	if dir.length() > 0.1:
		var target_yaw := atan2(-dir.x, -dir.z)
		model.rotation.y = lerp_angle(model.rotation.y, target_yaw - rotation.y, delta * 9.0)
	_animate(dir.length() > 0.1, clamp(dir.length(),0.0,1.0))
	if carrying_egg and game:
		game.check_farm_delivery(self)

func _animate(moving: bool, intensity: float) -> void:
	var swing := sin(phase * (11.0 if moving else 2.0)) * (0.78 if moving else 0.04) * intensity
	for i in range(limbs.size()):
		limbs[i].rotation.x = lerp(limbs[i].rotation.x, swing * (1.0 if i % 2 == 0 else -1.0), 0.28)
	model.position.y = (abs(sin(phase*11.0))*0.06 if moving else sin(phase*1.7)*0.015)

func set_carrying(egg: Node3D) -> void:
	carrying_egg = egg
	if egg:
		egg.reparent(carry_anchor)
		egg.position = Vector3.ZERO
		egg.rotation = Vector3.ZERO

func drop_egg(world_position: Vector3) -> void:
	if not carrying_egg: return
	var e := carrying_egg; carrying_egg = null
	e.reparent(game)
	e.global_position = world_position

func hit_by_guardian(_guardian: Node) -> void:
	if game:
		game.on_player_hit(self)

func start_training(marker: Transform3D) -> void:
	training = true
	training_transform = marker

func stop_training() -> void:
	training = false
	global_position += Vector3(0,0,2.0)

func refresh_trail() -> void:
	trail.call("set_level", int(Save.data.trail_level))
