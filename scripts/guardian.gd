extends CharacterBody3D

enum State { SLEEP, CHASE, RETURN }

@export var guardian_type: String = "Chicken"
@export var base_speed: float = 12.0
@export var hit_radius: float = 2.8
@export var scale_factor: float = 1.0

var state: State = State.SLEEP
var home: Vector3 = Vector3.ZERO
var target: CharacterBody3D
var phase: float = 0.0
var visual: Node3D
var limbs: Array[Node3D] = []
var alert_label: Label3D
var wake_audio: AudioStreamPlayer3D
var hit_audio: AudioStreamPlayer3D
var sleep_tilt: float = -0.16
var sleep_drop: float = -0.55

func _ready() -> void:
	home = global_position
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	_build_model()
	_build_collision()
	_build_alert()
	_configure_type()
	_apply_sleep_pose()

	wake_audio = AudioStreamPlayer3D.new()
	wake_audio.stream = _tone_stream(255.0, 0.32, 0.38)
	wake_audio.max_distance = 90.0
	add_child(wake_audio)

	hit_audio = AudioStreamPlayer3D.new()
	hit_audio.stream = _tone_stream(86.0, 0.20, 0.58)
	hit_audio.max_distance = 75.0
	add_child(hit_audio)

func _configure_type() -> void:
	match guardian_type:
		"Chicken":
			sleep_tilt = -0.34
			sleep_drop = -1.05 * scale_factor
			hit_radius = 3.0
		"Swan":
			sleep_tilt = -0.22
			sleep_drop = -0.72 * scale_factor
			hit_radius = 3.2
		"Scorpion":
			sleep_tilt = -0.05
			sleep_drop = -0.32 * scale_factor
			hit_radius = 3.4
		"Tiger", "NineTailFox", "EnchantedLion":
			sleep_tilt = -0.20
			sleep_drop = -0.62 * scale_factor
			hit_radius = 3.6
		"Yeti", "GorillaKing":
			sleep_tilt = -0.18
			sleep_drop = -1.0 * scale_factor
			hit_radius = 4.2
		"Cerberus", "AngelDemon":
			sleep_tilt = -0.16
			sleep_drop = -0.75 * scale_factor
			hit_radius = 4.0
		"Moby":
			sleep_tilt = 0.0
			sleep_drop = -1.15 * scale_factor
			hit_radius = 5.2
		"TRex", "CosmicSkeleton":
			sleep_tilt = -0.14
			sleep_drop = -0.9 * scale_factor
			hit_radius = 4.5

func _tone_stream(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var rate: int = 22050
	var count: int = int(rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in range(count):
		var t: float = float(i) / float(rate)
		var env: float = 1.0 - float(i) / maxf(1.0, float(count))
		var wobble: float = 1.0 + 0.08 * sin(TAU * 7.0 * t)
		var sample: int = int(sin(TAU * freq * wobble * t) * 32767.0 * volume * env)
		bytes[i*2] = sample & 255
		bytes[i*2+1] = (sample >> 8) & 255
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _mat(color: Color, emission: Color = Color.BLACK, metal: float = 0.0, rough: float = 0.65) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	if emission != Color.BLACK:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = 2.4
	return m

func _mesh(mesh: Mesh, pos: Vector3, scale_v: Vector3, color: Color, parent: Node3D = visual, emission: Color = Color.BLACK) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = mesh
	n.position = pos * scale_factor
	n.scale = scale_v * scale_factor
	n.material_override = _mat(color, emission)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(n)
	return n

func _sphere(pos: Vector3, scale_v: Vector3, color: Color, parent: Node3D = visual, emission: Color = Color.BLACK) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radial_segments = 20
	s.rings = 12
	return _mesh(s, pos, scale_v, color, parent, emission)

func _box(pos: Vector3, size_v: Vector3, color: Color, parent: Node3D = visual, emission: Color = Color.BLACK) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size_v
	return _mesh(b, pos, Vector3.ONE, color, parent, emission)

func _cyl(pos: Vector3, radius: float, height: float, color: Color, rot: Vector3 = Vector3.ZERO, parent: Node3D = visual, emission: Color = Color.BLACK) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = 16
	var n := _mesh(c, pos, Vector3.ONE, color, parent, emission)
	n.rotation = rot
	return n

func _eye(pos: Vector3, color: Color = Color(0.12,0.85,1.0)) -> void:
	_sphere(pos, Vector3(0.18,0.18,0.12), color, visual, color)

func _limb(pos: Vector3, size_v: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = pos * scale_factor
	visual.add_child(pivot)
	var b := BoxMesh.new()
	b.size = size_v * scale_factor
	var n := MeshInstance3D.new()
	n.mesh = b
	n.position.y = -size_v.y * scale_factor * 0.45
	n.material_override = _mat(color)
	pivot.add_child(n)
	limbs.append(pivot)
	return pivot

func _build_model() -> void:
	match guardian_type:
		"Chicken":
			_sphere(Vector3(0,2.4,0),Vector3(3.2,2.7,3.0),Color(0.98,0.98,0.95))
			_sphere(Vector3(0,5.15,-0.4),Vector3(2.15,1.9,1.95),Color(1,1,0.98))
			_box(Vector3(0,4.75,-2.45),Vector3(1.45,0.62,1.8),Color(1.0,0.64,0.06))
			for x in [-0.78,0.78]:
				_eye(Vector3(x,5.48,-1.92),Color(0.08,0.08,0.10))
			for x in [-1.15,1.15]:
				_limb(Vector3(x,0.95,0.2),Vector3(0.64,2.0,0.64),Color(0.95,0.60,0.08))
			for x in [-2.7,2.7]:
				var wing := _sphere(Vector3(x,2.7,0.2),Vector3(0.85,2.0,2.25),Color(0.91,0.93,0.91))
				wing.rotation.z = 0.42 * sign(x)
			for x in [-0.58,0.0,0.58]:
				_sphere(Vector3(x,6.55,-0.1),Vector3(0.36,0.55,0.34),Color(0.92,0.08,0.08))

		"Swan":
			_sphere(Vector3(0,2.6,0),Vector3(3.5,2.25,4.1),Color(0.98,0.99,1.0))
			_cyl(Vector3(0,5.2,-0.4),0.82,5.0,Color(0.99,0.99,1.0),Vector3(0.32,0,0))
			_sphere(Vector3(0,7.7,-1.2),Vector3(1.45,1.35,1.5),Color(1,1,1))
			_box(Vector3(0,7.35,-2.72),Vector3(1.0,0.52,1.65),Color(1.0,0.52,0.05))
			for x in [-0.45,0.45]:
				_eye(Vector3(x,7.98,-2.1),Color(0.04,0.04,0.06))
			for x in [-2.85,2.85]:
				var wing2 := _sphere(Vector3(x,3.0,0),Vector3(1.0,2.1,3.5),Color(0.91,0.94,1.0))
				wing2.rotation.z = 0.34 * sign(x)

		"Scorpion":
			_sphere(Vector3(0,1.65,0),Vector3(3.2,1.55,3.7),Color(0.42,0.12,0.59),visual,Color(0.23,0.04,0.50))
			for z in [1.5,3.1,4.6]:
				_sphere(Vector3(0,1.8,z),Vector3(1.7,1.25,1.7),Color(0.57,0.15,0.72))
			for side in [-1,1]:
				for i in range(4):
					var leg := _limb(Vector3(float(side)*(2.0+float(i)*0.26),1.25,-1.8+float(i)*1.15),Vector3(3.0,0.42,0.48),Color(0.31,0.07,0.42))
					leg.rotation.z = 1.10 * float(side)
				_sphere(Vector3(float(side)*4.1,1.9,-2.4),Vector3(1.35,0.9,1.25),Color(0.62,0.18,0.78))
			for i in range(4):
				_sphere(Vector3(0,2.7+float(i)*0.85,5.5+float(i)*0.65),Vector3(1.05,0.85,1.12),Color(0.52,0.13,0.69))
			_sphere(Vector3(0,6.5,8.2),Vector3(0.75,1.45,0.75),Color(0.8,0.24,1.0),visual,Color(0.7,0.08,1.0))
			for x in [-0.7,0.7]:
				_eye(Vector3(x,2.35,-3.15),Color(1,0.10,0.45))

		"Tiger":
			_build_big_cat(Color(0.92,0.43,0.07),Color(0.10,0.06,0.03),Color(0.25,1.0,0.30))

		"Yeti":
			_sphere(Vector3(0,4.0,0),Vector3(4.4,4.4,3.4),Color(0.87,0.94,1.0))
			_sphere(Vector3(0,7.9,-0.4),Vector3(2.5,2.25,2.4),Color(0.93,0.97,1.0))
			_sphere(Vector3(0,7.45,-2.3),Vector3(1.55,1.05,0.72),Color(0.40,0.46,0.56))
			for x in [-0.82,0.82]:
				_eye(Vector3(x,8.15,-2.35),Color(0.08,0.70,1.0))
			for x in [-3.6,3.6]:
				var arm := _limb(Vector3(x,5.0,0),Vector3(1.25,6.0,1.25),Color(0.80,0.89,0.98))
				arm.rotation.z = 0.20 * sign(x)
			for x in [-1.8,1.8]:
				_limb(Vector3(x,1.9,0),Vector3(1.45,4.0,1.45),Color(0.74,0.84,0.94))
			for x in [-1,1]:
				_cyl(Vector3(float(x)*1.8,10.0,-0.5),0.32,3.0,Color(0.22,0.25,0.30),Vector3(0,0,float(x)*0.55))

		"Cerberus":
			_sphere(Vector3(0,3.1,0),Vector3(4.6,3.0,5.4),Color(0.17,0.15,0.19),visual,Color(0.22,0.02,0.02))
			for hx in [-2.4,0.0,2.4]:
				_sphere(Vector3(hx,6.1,-3.8),Vector3(2.0,1.9,2.2),Color(0.20,0.17,0.22))
				_eye(Vector3(hx-0.55,6.4,-5.45),Color(1,0.10,0.02))
				_eye(Vector3(hx+0.55,6.4,-5.45),Color(1,0.10,0.02))
			for x in [-2.2,2.2]:
				_limb(Vector3(x,1.8,-2.3),Vector3(1.0,3.5,1.1),Color(0.13,0.12,0.15))
				_limb(Vector3(x,1.8,2.1),Vector3(1.0,3.5,1.1),Color(0.13,0.12,0.15))
			_sphere(Vector3(0,4.6,2.7),Vector3(2.8,1.2,2.3),Color(0.30,0.04,0.02),visual,Color(1.0,0.12,0.02))

		"Moby":
			_sphere(Vector3(0,4.0,0),Vector3(7.0,3.7,9.2),Color(0.22,0.52,0.72))
			_sphere(Vector3(0,2.5,-1.0),Vector3(5.9,1.8,7.5),Color(0.78,0.90,0.95))
			for x in [-2.0,2.0]:
				_eye(Vector3(x,4.8,-7.3),Color(0.025,0.07,0.12))
			for x in [-6.2,6.2]:
				var fin := _sphere(Vector3(x,3.4,0),Vector3(2.5,0.52,4.0),Color(0.17,0.43,0.62))
				fin.rotation.z = 0.24 * sign(x)
			_box(Vector3(0,3.8,8.6),Vector3(7.8,0.65,3.0),Color(0.17,0.43,0.62))

		"TRex":
			_sphere(Vector3(0,4.0,0),Vector3(4.7,3.5,6.6),Color(0.25,0.58,0.23))
			_sphere(Vector3(0,7.5,-5.1),Vector3(3.7,2.6,4.2),Color(0.30,0.66,0.28))
			_box(Vector3(0,6.8,-8.2),Vector3(4.9,1.95,3.0),Color(0.33,0.69,0.30))
			for x in [-1.15,1.15]:
				_eye(Vector3(x,8.1,-8.5),Color(1.0,0.76,0.10))
			for x in [-2.3,2.3]:
				_limb(Vector3(x,1.9,0.8),Vector3(1.35,4.6,1.45),Color(0.22,0.52,0.20))
				var arm2 := _limb(Vector3(x,6.0,-3.2),Vector3(0.55,2.2,0.65),Color(0.27,0.60,0.25))
				arm2.rotation.z = 0.72 * sign(x)
			_cyl(Vector3(0,4.5,7.2),1.05,10.5,Color(0.24,0.56,0.22),Vector3(1.2,0,0))

		"CosmicSkeleton":
			_sphere(Vector3(0,4.0,0),Vector3(4.5,3.0,6.0),Color(0.10,0.05,0.18),visual,Color(0.30,0.05,0.65))
			for z in [-3.0,-1.3,0.4,2.1]:
				_box(Vector3(0,4.2,z),Vector3(5.8,0.34,0.42),Color(0.72,0.67,0.88),visual,Color(0.28,0.12,0.55))
			_sphere(Vector3(0,7.0,-4.8),Vector3(2.5,2.0,2.6),Color(0.24,0.13,0.38),visual,Color(0.4,0.08,0.8))
			for x in [-0.85,0.85]:
				_eye(Vector3(x,7.4,-6.6),Color(0.78,0.18,1.0))
			for x in [-2.3,2.3]:
				_limb(Vector3(x,1.9,0.8),Vector3(0.85,4.2,0.9),Color(0.64,0.59,0.78))
			for x in [-4.2,4.2]:
				var wing3 := _sphere(Vector3(x,5.0,0),Vector3(2.8,0.42,4.8),Color(0.25,0.07,0.48),visual,Color(0.25,0.05,0.60))
				wing3.rotation.z = 0.28 * sign(x)

		"NineTailFox":
			_build_big_cat(Color(0.96,0.90,0.93),Color(0.75,0.16,0.36),Color(1.0,0.25,0.65))
			for i in range(9):
				var angle: float = -1.05 + float(i) * 0.26
				var tail := _cyl(Vector3(sin(angle)*3.0,4.2,5.2+cos(angle)*1.4),0.45,6.0,Color(0.96,0.80,0.88),Vector3(1.1,0,angle))
				tail.material_override = _mat(Color(0.96,0.80,0.88),Color(0.35,0.04,0.16))

		"GorillaKing":
			_sphere(Vector3(0,4.6,0),Vector3(5.2,4.6,3.8),Color(0.20,0.18,0.17))
			_sphere(Vector3(0,8.2,-0.7),Vector3(2.8,2.4,2.4),Color(0.26,0.22,0.20))
			_sphere(Vector3(0,7.6,-2.5),Vector3(1.8,1.1,0.75),Color(0.44,0.34,0.26))
			for x in [-0.85,0.85]:
				_eye(Vector3(x,8.4,-2.55),Color(1.0,0.72,0.12))
			for x in [-4.4,4.4]:
				var arm3 := _limb(Vector3(x,5.5,0),Vector3(1.7,7.2,1.8),Color(0.16,0.14,0.13))
				arm3.rotation.z = 0.18 * sign(x)
			for x in [-1.8,1.8]:
				_limb(Vector3(x,2.1,0),Vector3(1.6,4.4,1.7),Color(0.17,0.15,0.14))
			_box(Vector3(0,10.5,-0.4),Vector3(4.8,0.55,2.2),Color(0.93,0.70,0.10),visual,Color(0.55,0.26,0.02))

		"AngelDemon":
			_sphere(Vector3(0,4.1,0),Vector3(4.1,3.8,3.2),Color(0.60,0.60,0.66))
			_sphere(Vector3(0,7.4,-0.5),Vector3(2.3,2.1,2.1),Color(0.78,0.74,0.76))
			_box(Vector3(-2.1,4.0,0),Vector3(4.0,6.3,3.5),Color(0.90,0.92,1.0),visual,Color(0.55,0.68,1.0))
			_box(Vector3(2.1,4.0,0),Vector3(4.0,6.3,3.5),Color(0.20,0.06,0.07),visual,Color(0.70,0.06,0.02))
			_eye(Vector3(-0.75,7.7,-2.05),Color(0.30,0.65,1.0))
			_eye(Vector3(0.75,7.7,-2.05),Color(1.0,0.16,0.04))
			for x in [-4.8,4.8]:
				var wing4 := _sphere(Vector3(x,5.7,0),Vector3(2.8,0.5,5.0),Color(0.88,0.92,1.0) if x < 0 else Color(0.28,0.04,0.05),visual,Color(0.35,0.55,1.0) if x < 0 else Color(0.8,0.05,0.02))
				wing4.rotation.z = 0.30 * sign(x)
			for x in [-1.7,1.7]:
				_limb(Vector3(x,1.9,0),Vector3(1.2,4.0,1.3),Color(0.55,0.53,0.57))

		"EnchantedLion":
			_build_big_cat(Color(0.52,0.78,0.24),Color(0.18,0.42,0.12),Color(0.22,1.0,0.55))
			for i in range(10):
				var a: float = float(i) * TAU / 10.0
				_sphere(Vector3(cos(a)*2.7,5.6+sin(a)*0.45,-3.1),Vector3(0.65,1.15,0.65),Color(0.10,0.48,0.22),visual,Color(0.05,0.35,0.14))

		_:
			_sphere(Vector3(0,3,0),Vector3(3,3,3),Color(0.7,0.2,0.2))

func _build_big_cat(body_color: Color, stripe_color: Color, eye_color: Color) -> void:
	_sphere(Vector3(0,3.0,0),Vector3(3.4,2.5,4.8),body_color)
	_sphere(Vector3(0,5.1,-3.5),Vector3(2.3,2.0,2.2),body_color.lightened(0.04))
	for x in [-0.92,0.92]:
		_eye(Vector3(x,5.45,-5.15),eye_color)
	for x in [-1.8,1.8]:
		_limb(Vector3(x,1.9,-2.2),Vector3(0.85,3.25,0.95),body_color.darkened(0.08))
		_limb(Vector3(x,1.9,2.1),Vector3(0.85,3.25,0.95),body_color.darkened(0.08))
	for z in [-2.5,-0.6,1.4]:
		_box(Vector3(0,3.25,z),Vector3(6.2,0.30,0.27),stripe_color)
	_cyl(Vector3(0,3.3,5.2),0.36,6.1,body_color,Vector3(1.25,0,0))

func _build_collision() -> void:
	var c := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 2.55 * scale_factor
	cap.height = 6.8 * scale_factor
	c.shape = cap
	c.position.y = 3.0 * scale_factor
	add_child(c)

func _build_alert() -> void:
	alert_label = Label3D.new()
	alert_label.text = "Z"
	alert_label.font_size = 84
	alert_label.outline_size = 18
	alert_label.modulate = Color(0.45,0.78,1.0)
	alert_label.position = Vector3(0,10.8 * scale_factor,0)
	alert_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(alert_label)

func _apply_sleep_pose() -> void:
	visual.rotation.z = sleep_tilt
	visual.position.y = sleep_drop

func wake_up(p: CharacterBody3D) -> void:
	target = p
	state = State.CHASE
	alert_label.text = "!"
	alert_label.modulate = Color(1,0.10,0.06)
	var tw := create_tween()
	tw.tween_property(visual,"rotation:z",0.0,0.16)
	tw.parallel().tween_property(visual,"position:y",0.0,0.16)
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
		State.CHASE:
			if not is_instance_valid(target):
				calm_down()
				return
			if target.global_position.z > 12.0:
				calm_down()
				return
			var to: Vector3 = target.global_position - global_position
			to.y = 0
			if to.length() > 0.2:
				var desired: Vector3 = to.normalized()
				var close_mult: float = 1.38 if to.length() < 22.0 else 1.0
				var wanted: Vector3 = desired * base_speed * close_mult
				velocity.x = move_toward(velocity.x,wanted.x,base_speed*4.8*delta)
				velocity.z = move_toward(velocity.z,wanted.z,base_speed*4.8*delta)
				rotation.y = lerp_angle(rotation.y,atan2(-desired.x,-desired.z),delta*5.7)
			move_and_slide()
			if global_position.distance_to(target.global_position) < hit_radius * scale_factor:
				hit_audio.play()
				target.call_deferred("hit_by_guardian",self)
				calm_down()
		State.RETURN:
			var to_home: Vector3 = home - global_position
			to_home.y = 0
			if to_home.length() < 1.2:
				global_position = home
				velocity = Vector3.ZERO
				state = State.SLEEP
				alert_label.text = "Z"
				alert_label.modulate = Color(0.45,0.78,1.0)
				_apply_sleep_pose()
			else:
				var d: Vector3 = to_home.normalized()
				velocity.x = d.x * base_speed * 0.62
				velocity.z = d.z * base_speed * 0.62
				rotation.y = lerp_angle(rotation.y,atan2(-d.x,-d.z),delta*3.2)
				move_and_slide()

func _animate(_delta: float) -> void:
	if state == State.CHASE or state == State.RETURN:
		var stride: float = sin(phase * (9.2 if state == State.CHASE else 6.0)) * 0.66
		for i in range(limbs.size()):
			limbs[i].rotation.x = stride * (1.0 if i % 2 == 0 else -1.0)
		visual.position.y = abs(sin(phase*9.2)) * 0.20 * scale_factor
		visual.rotation.z = sin(phase*4.2) * 0.032
		visual.rotation.x = -0.06 if state == State.CHASE else 0.0
	else:
		for limb in limbs:
			limb.rotation.x = lerp(limb.rotation.x,0.0,0.08)
		visual.position.y = sleep_drop + sin(phase*1.5)*0.045*scale_factor
		visual.rotation.z = sleep_tilt + sin(phase*1.2)*0.012
		visual.rotation.x = 0.0
