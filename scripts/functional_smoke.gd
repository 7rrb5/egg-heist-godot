extends SceneTree

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	failed = true
	push_error("FUNCTIONAL TEST FAILED: " + message)

func _run() -> void:
	var packed: PackedScene = load("res://main.tscn")
	if packed == null:
		_fail("main scene could not load")
		quit(1)
		return
	var game: Node3D = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await process_frame

	var p: CharacterBody3D = game.get("player")
	if p == null:
		_fail("player missing")
		quit(1)
		return

	var farms: Array = game.get("farm_centers")
	if farms.size() != 12:
		_fail("expected 12 farms, got %d" % farms.size())

	var guardians: Array = game.get("guardians")
	if guardians.size() < 13:
		_fail("expected 13 guardians, got %d" % guardians.size())

	var egg: Node3D = null
	for n in get_nodes_in_group("interactable"):
		if n is Node3D and str(n.get_meta("kind","")) == "egg":
			egg = n
			break
	if egg == null:
		_fail("no interactable egg found")
	else:
		var before_pets: int = int(game.get("pet_nodes").size())
		p.global_position = egg.global_position + Vector3(0,0,2.0)
		game.call("try_interact", p)
		await process_frame
		if p.get("carrying_egg") == null:
			_fail("egg pickup failed")
		else:
			var guardian: Node = p.get("carrying_egg").get_meta("guardian")
			if guardian == null or int(guardian.get("state")) != 1:
				_fail("guardian did not enter chase state after egg theft")
			p.global_position = farms[0]
			game.call("check_farm_delivery", p)
			await process_frame
			if p.get("carrying_egg") != null:
				_fail("farm delivery did not clear carried egg")
			if int(game.get("pet_nodes").size()) != before_pets + 1:
				_fail("farm delivery did not create an animal")

	var treadmill: Node3D = game.get("player_treadmill")
	if treadmill == null:
		_fail("player treadmill missing")
	else:
		game.call("_toggle_treadmill", p, treadmill)
		await process_frame
		if not bool(p.get("training")):
			_fail("treadmill did not start training")
		game.call("_toggle_treadmill", p, treadmill)
		await process_frame
		if bool(p.get("training")):
			_fail("treadmill did not stop training")

	var shop_panel: PanelContainer = game.get("shop_panel")
	game.call("_open_shop", "trail")
	await process_frame
	if shop_panel == null or not shop_panel.visible:
		_fail("trail shop did not open")
	else:
		shop_panel.visible = false
	game.call("_open_shop", "treadmill")
	await process_frame
	if shop_panel == null or not shop_panel.visible:
		_fail("treadmill shop did not open")

	var save: Node = root.get_node_or_null("Save")
	if save == null:
		_fail("Save autoload missing")
		quit(1)
		return
	var save_data: Dictionary = save.get("data")
	var old_farm: int = int(save_data.farm_level)
	var old_cash: float = float(save_data.cash)
	save_data.cash = 1.0e18
	save.set("data", save_data)
	if old_farm < 13:
		game.call("_upgrade_farm", 0)
		await process_frame
		save_data = save.get("data")
		if int(save_data.farm_level) != old_farm + 1:
			_fail("farm upgrade failed")
	save_data = save.get("data")
	save_data.farm_level = old_farm
	save_data.cash = old_cash
	save.set("data", save_data)

	save_data = save.get("data")
	var old_trail: int = int(save_data.trail_level)
	save_data.cash = 1.0e18
	save.set("data", save_data)
	game.set("current_shop", "trail")
	if old_trail < 11:
		game.call("_buy_shop")
		await process_frame
		save_data = save.get("data")
		if int(save_data.trail_level) != old_trail + 1:
			_fail("trail purchase failed")
	save_data = save.get("data")
	save_data.trail_level = old_trail
	save_data.cash = old_cash
	save.set("data", save_data)
	save.call("save_data")

	if failed:
		quit(1)
	else:
		print("FUNCTIONAL TEST PASSED: player, eggs, guardians, farm delivery, treadmill, shops and upgrades")
		quit(0)
