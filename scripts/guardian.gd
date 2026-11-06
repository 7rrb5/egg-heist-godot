extends CharacterBody3D

signal player_hit(guardian)

enum State { SLEEP, CHASE, RETURN }
@export var guardian_type := "Chicken"
@export var base_speed := 12.0
@export var hit_radius := 2.7
@export var scale_factor := 1.0

var state := State.SLEEP
var home := Vector3.ZERO
var target: CharacterBody3D
var phase := 0.0
var visual: Node3D
var limbs: Array[Node3D] = []
var alert_label: Label3D
var wake_audio: AudioStreamPlayer3D
var hit_audio: AudioStreamPlayer3D

func _ready() -> void:
	home = global_position
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_build_model()
	_build_collision()
	_build_alert()
	wake_audio = AudioStreamPlayer3D.new()
	wake_audio.stream = _tone_stream(235.0, 0.34, 0.38)
	wake_audio.max_distance = 75.0
	add_child(wake_audio)
	hit_audio = AudioStreamPlayer3D.new()
	hit_audio.stream = _tone_stream(92.0, 0.20, 0.55)
	hit_audio.max_distance = 60.0
	add_child(hit_audio)

func _tone_stream(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var bytes := PackedByteArray(); bytes.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(rate)
		var env := 1.0 - float(i) / max(1.0, float(count))
		var wobble := 1.0 + 0.08 * sin(TAU * 7.0 * t)
		var sample := int(sin(TAU * freq * wobble * t) * 32767.0 * volume * env)
		bytes[i*2] = sample & 255; bytes[i*2+1] = (sample >> 8) & 255
	var wav := AudioStreamWAV.new(); wav.format = AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate = rate; wav.stereo = false; wav.data = bytes
	return wav

func _mat(color: Color, emission := Color.BLACK, metal := 0.0, rough := 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 2.2
	return m

func _mesh(mesh: Mesh, pos: Vector3, scale_v: Vector3, color: Color, parent: Node3D = visual, emission := Color.BLACK) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.position = pos
	n.scale = scale_v * scale_factor
	n.material_override = _mat(color, emission)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(n)
	return n

func _sphere(pos: Vector3, scale_v: Vector3, color: Color, parent: Node3D = visual, emission := Color.BLACK) -> MeshInstance3D:
	var s := SphereMesh.new(); s.radial_segments = 18; s.rings = 10
	return _mesh(s, pos * scale_factor, scale_v, color, parent, emission)

func _box(pos: Vector3, size_v: Vector3, color: Color, parent: Node3D = visual, emission := Color.BLACK) -> MeshInstance3D:
	var b := BoxMesh.new(); b.size = size_v
	return _mesh(b, pos * scale_factor, Vector3.ONE, color, parent, emission)

func _cyl(pos: Vector3, radius: float, height: float, color: Color, rot := Vector3.ZERO, parent: Node3D = visual) -> MeshInstance3D:
	var c := CylinderMesh.new(); c.top_radius = radius; c.bottom_radius = radius; c.height = height; c.radial_segments = 14
	var n := _mesh(c, pos * scale_factor, Vector3.ONE * scale_factor, color, parent)
	n.rotation = rot
	return n

func _eye(pos: Vector3, color := Color(0.15,0.9,1.0)) -> void:
	_sphere(pos, Vector3(0.18,0.18,0.12), color, visual, color)

func _limb(pos: Vector3, size_v: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new(); pivot.position = pos * scale_factor; visual.add_child(pivot)
	var b := BoxMesh.new(); b.size = size_v * scale_factor
	var n := MeshInstance3D.new(); n.mesh = b; n.position.y = -size_v.y * scale_factor * 0.45; n.material_override = _mat(color); pivot.add_child(n)
	limbs.append(pivot)
	return pivot

func _build_model() -> void:
	match guardian_type:
		"Chicken":
			_sphere(Vector3(0,2.8,0), Vector3(2.9,3.2,2.6), Color(0.96,0.96,0.92))
			_sphere(Vector3(0,6.0,-0.15), Vector3(2.0,1.9,1.8), Color(1,1,0.96))
			_box(Vector3(0,5.7,-2.0), Vector3(1.3,0.65,1.7), Color(1.0,0.66,0.08))
			for x in [-0.75,0.75]: _eye(Vector3(x,6.35,-1.65), Color(1,0.18,0.08))
			for x in [-1.15,1.15]: _limb(Vector3(x,1.0,0), Vector3(0.62,2.3,0.62), Color(0.95,0.63,0.12))
			for x in [-2.65,2.65]:
				var w := _sphere(Vector3(x,3.2,0.1), Vector3(0.8,2.3,2.0), Color(0.91,0.92,0.9)); w.rotation.z = 0.45 * sign(x)
		"Swan":
			_sphere(Vector3(0,2.7,0), Vector3(3.4,2.3,4.0), Color(0.97,0.98,1))
			_cyl(Vector3(0,5.3,-0.2), 0.85, 5.4, Color(0.98,0.99,1), Vector3(0.35,0,0))
			_sphere(Vector3(0,8.0,-1.1), Vector3(1.45,1.35,1.5), Color(1,1,1))
			_box(Vector3(0,7.7,-2.65), Vector3(1.0,0.55,1.75), Color(1.0,0.55,0.08))
			for x in [-0.45,0.45]: _eye(Vector3(x,8.3,-2.15), Color(0.08,0.08,0.1))
			for x in [-2.8,2.8]:
				var wing := _sphere(Vector3(x,3.0,0), Vector3(1.0,2.2,3.4), Color(0.91,0.94,1)); wing.rotation.z = 0.35 * sign(x)
		"Scorpion":
			_sphere(Vector3(0,2.0,0), Vector3(3.0,1.8,3.5), Color(0.42,0.14,0.62), visual, Color(0.2,0.05,0.55))
			for z in [1.5,3.0,4.4]: _sphere(Vector3(0,2.2,z), Vector3(1.8,1.45,1.7), Color(0.55,0.16,0.72))
			for side in [-1,1]:
				for i in range(4):
					var leg := _limb(Vector3(side*(2.2+i*0.25),1.4,-1.7+i*1.1), Vector3(3.2,0.45,0.5), Color(0.3,0.08,0.42)); leg.rotation.z = 1.15*side
				var claw := _sphere(Vector3(side*4.1,2.0,-2.2), Vector3(1.4,0.9,1.3), Color(0.62,0.18,0.74))
			for i in range(4): _sphere(Vector3(0,3.0+i*0.85,5.5+i*0.6), Vector3(1.15,0.9,1.2), Color(0.5,0.14,0.68))
			_sphere(Vector3(0,6.8,8.1), Vector3(0.8,1.5,0.8), Color(0.8,0.25,1.0), visual, Color(0.75,0.1,1.0))
			for x in [-0.7,0.7]: _eye(Vector3(x,2.8,-3.1), Color(1,0.15,0.5))
		"Tiger":
			_sphere(Vector3(0,3.0,0), Vector3(3.3,2.5,4.7), Color(0.92,0.42,0.08))
			_sphere(Vector3(0,5.0,-3.4), Vector3(2.25,2.0,2.2), Color(0.94,0.48,0.09))
			for x in [-0.9,0.9]: _eye(Vector3(x,5.35,-5.0), Color(0.25,1.0,0.35))
			for x in [-1.8,1.8]:
				_limb(Vector3(x,2.0,-2.2), Vector3(0.85,3.3,0.95), Color(0.83,0.32,0.06))
				_limb(Vector3(x,2.0,2.1), Vector3(0.85,3.3,0.95), Color(0.83,0.32,0.06))
			for z in [-2.5,-0.6,1.4]: _box(Vector3(0,3.2,z), Vector3(6.1,0.32,0.28), Color(0.12,0.07,0.04))
			var tail := _cyl(Vector3(0,3.2,5.1),0.38,6.0,Color(0.92,0.42,0.08),Vector3(1.25,0,0)); tail.rotation.z = 0.25
		"Yeti":
			_sphere(Vector3(0,4.2,0), Vector3(4.3,4.6,3.3), Color(0.88,0.94,1.0))
			_sphere(Vector3(0,8.1,-0.3), Vector3(2.6,2.3,2.4), Color(0.92,0.96,1))
			_sphere(Vector3(0,7.7,-2.25), Vector3(1.55,1.15,0.75), Color(0.42,0.48,0.58))
			for x in [-0.8,0.8]: _eye(Vector3(x,8.35,-2.35), Color(0.1,0.75,1.0))
			for x in [-3.7,3.7]:
				var arm := _limb(Vector3(x,5.0,0), Vector3(1.25,6.2,1.25), Color(0.82,0.9,0.98)); arm.rotation.z = 0.22*sign(x)
			for x in [-1.8,1.8]: _limb(Vector3(x,2.0,0), Vector3(1.4,4.2,1.45), Color(0.76,0.86,0.95))
			for x in [-1,1]:
				var horn := _cyl(Vector3(x*1.8,10.2,-0.5),0.35,3.1,Color(0.24,0.27,0.32),Vector3(0,0,x*0.55)); horn.scale.x *= 0.7
		"Cerberus":
			_sphere(Vector3(0,3.3,0), Vector3(4.5,3.0,5.2), Color(0.18,0.16,0.2), visual, Color(0.28,0.04,0.04))
			for hx in [-2.4,0,2.4]:
				_sphere(Vector3(hx,6.4,-3.7), Vector3(2.1,2.0,2.2), Color(0.2,0.18,0.23))
				_eye(Vector3(hx-0.55,6.7,-5.35), Color(1,0.12,0.04)); _eye(Vector3(hx+0.55,6.7,-5.35), Color(1,0.12,0.04))
			for x in [-2.2,2.2]:
				_limb(Vector3(x,2.0,-2.3), Vector3(1.0,3.6,1.1), Color(0.14,0.13,0.16)); _limb(Vector3(x,2.0,2.2), Vector3(1.0,3.6,1.1), Color(0.14,0.13,0.16))
			_sphere(Vector3(0,5.0,2.5), Vector3(2.6,1.2,2.4), Color(0.24,0.05,0.03), visual, Color(1.0,0.18,0.03))
		"Moby":
			_sphere(Vector3(0,4.3,0), Vector3(6.8,3.8,9.0), Color(0.23,0.53,0.72))
			_sphere(Vector3(0,2.8,-1.0), Vector3(5.8,2.0,7.5), Color(0.78,0.9,0.95))
			for x in [-2.0,2.0]: _eye(Vector3(x,5.0,-7.2), Color(0.04,0.1,0.16))
			for x in [-6.2,6.2]:
				var fin := _sphere(Vector3(x,3.5,0), Vector3(2.5,0.55,4.0), Color(0.18,0.44,0.62)); fin.rotation.z = 0.25*sign(x)
			var tail := _box(Vector3(0,4.0,8.3), Vector3(7.5,0.7,3.2), Color(0.18,0.44,0.62)); tail.rotation.y = 0.0
		"TRex":
			_sphere(Vector3(0,4.0,0), Vector3(4.6,3.6,6.5), Color(0.25,0.58,0.24))
			_sphere(Vector3(0,7.5,-5.0), Vector3(3.6,2.7,4.2), Color(0.3,0.66,0.29))
			_box(Vector3(0,6.8,-8.1), Vector3(4.8,2.0,3.0), Color(0.33,0.69,0.3))
			for x in [-1.15,1.15]: _eye(Vector3(x,8.2,-8.4), Color(1.0,0.78,0.12))
			for x in [-2.3,2.3]: _limb(Vector3(x,2.0,0.8), Vector3(1.35,4.7,1.45), Color(0.22,0.52,0.21))
			for x in [-2.3,2.3]:
				var arm := _limb(Vector3(x,6.0,-3.2), Vector3(0.55,2.3,0.65), Color(0.27,0.6,0.25)); arm.rotation.z = 0.75*sign(x)
			var tail2 := _cyl(Vector3(0,4.6,7.3),1.1,11.0,Color(0.24,0.56,0.23),Vector3(1.2,0,0)); tail2.scale.z *= 0.7
		_:
			_sphere(Vector3(0,3,0), Vector3(3,3,3), Color(0.7,0.2,0.2))

func _build_collision() -> void:
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 2.4 * scale_factor
	cap.height = 6.5 * scale_factor
	c.shape = cap
	c.position.y = 3.0 * scale_factor
	add_child(c)

func _build_alert() -> void:
	alert_label = Label3D.new()
	alert_label.text = "Z  Z"
	alert_label.font_size = 72
	alert_label.outline_size = 16
	alert_label.modulate = Color(0.75,0.9,1.0)
	alert_label.position = Vector3(0, 11.5 * scale_factor, 0)
	alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(alert_label)

func wake_up(p: CharacterBody3D) -> void:
	target = p
	state = State.CHASE
	alert_label.text = "!"
	alert_label.modulate = Color(1,0.12,0.08)
	wake_audio.play()

func calm_down() -> void:
	target = null
	state = State.RETURN
	alert_label.text = ""

func _physics_process(delta: float) -> void:
	phase += delta
	_animate(delta)
	match state:
		State.SLEEP:
			velocity = Vector3.ZERO
			visual.rotation.z = sin(phase * 1.2) * 0.018
		State.CHASE:
			if not is_instance_valid(target):
				calm_down(); return
			var to := target.global_position - global_position
			to.y = 0
			if to.length() > 0.2:
				var desired := to.normalized()
				var mult := 1.32 if to.length() < 20.0 else 1.0
				velocity.x = move_toward(velocity.x, desired.x * base_speed * mult, base_speed * 4.0 * delta)
				velocity.z = move_toward(velocity.z, desired.z * base_speed * mult, base_speed * 4.0 * delta)
				rotation.y = lerp_angle(rotation.y, atan2(-desired.x, -desired.z), delta * 5.5)
			move_and_slide()
			if global_position.distance_to(target.global_position) < hit_radius * scale_factor:
				hit_audio.play()
				target.call_deferred("hit_by_guardian", self)
				calm_down()
		State.RETURN:
			var to_home := home - global_position; to_home.y = 0
			if to_home.length() < 1.2:
				global_position = home
				velocity = Vector3.ZERO
				state = State.SLEEP
				alert_label.text = "Z  Z"
				alert_label.modulate = Color(0.75,0.9,1.0)
			else:
				var d := to_home.normalized()
				velocity.x = d.x * base_speed * 0.55
				velocity.z = d.z * base_speed * 0.55
				rotation.y = lerp_angle(rotation.y, atan2(-d.x,-d.z), delta*3.0)
				move_and_slide()

func _animate(_delta: float) -> void:
	if state == State.CHASE or state == State.RETURN:
		var swing := sin(phase * (8.5 if state == State.CHASE else 5.5)) * 0.62
		for i in range(limbs.size()):
			limbs[i].rotation.x = swing * (1.0 if i % 2 == 0 else -1.0)
		visual.position.y = abs(sin(phase * 8.5)) * 0.18 * scale_factor
		visual.rotation.z = sin(phase*4.0)*0.035
	else:
		for limb in limbs:
			limb.rotation.x = lerp(limb.rotation.x, 0.0, 0.08)
		visual.position.y = sin(phase*1.7)*0.07*scale_factor
