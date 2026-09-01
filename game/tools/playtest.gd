extends SceneTree
## End-to-end checks for the win/lose plumbing of every stage. Drives a real
## level scene rather than mocking it, so tile collision, the goal area, the
## suspicion loop and progression saving all get exercised.
##   Godot.exe --headless --path game --script res://tools/playtest.gd

var _fails: Array[String] = []
var _checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _ok(cond: bool, what: String) -> void:
	_checks += 1
	if cond:
		print("    pass  ", what)
	else:
		_fails.append(what)
		print("    FAIL  ", what)

func _steps(n: int) -> void:
	for i in n:
		await physics_frame

func _load_level(idx: int) -> Node:
	root.get_node("Game").current_level = idx
	paused = false          # never inherit a pause from the previous case
	var lv: Node = load("res://scenes/level.tscn").instantiate()
	root.add_child(lv)
	await _steps(4)
	return lv

func _drop(lv: Node) -> void:
	lv.queue_free()
	await _steps(2)

func _run() -> void:
	var game := root.get_node("Game")
	game.wipe_save()

	for idx in range(1, LevelData.count() + 1):
		var spec := LevelData.get_level(idx)
		print("\n=== ด่าน %d: %s ===" % [idx, spec["name"]])

		# ------------------------------------------------ world was built ---
		var lv := await _load_level(idx)
		_ok(lv.player != null, "player spawned")
		_ok(lv.goal != null, "goal zone exists")
		_ok(lv.get_tree().get_nodes_in_group("npc").size() == spec["npcs"].size(),
			"all %d NPCs spawned" % spec["npcs"].size())
		_ok(lv.get_tree().get_nodes_in_group("cctv").size() == spec["cameras"].size(),
			"all %d cameras spawned" % spec["cameras"].size())
		_ok(absf(lv.time_left - spec["time"]) < 1.0, "clock started at %.0fs" % spec["time"])

		# the player must land on solid ground rather than fall out of the map
		var y0: float = lv.player.global_position.y
		await _steps(30)
		_ok(lv.player.global_position.y < y0 + 40.0, "player rests on the floor at spawn")
		_ok(lv.player.is_on_floor(), "player reports standing on floor")

		# ------------------------------------------------------- winning ----
		lv.player.global_position = lv.goal.global_position + Vector2(0, -2)
		await _steps(12)
		if spec.get("must_survive", false):
			_ok(lv.phase == 0, "reaching the safe zone does not end the stage yet")
			_ok(lv.goal.inside, "player registered inside the safe zone")
			lv.time_left = 0.02
			await _steps(12)
			_ok(lv.phase == 1, "bell while inside the safe zone wins the stage")
		else:
			_ok(lv.phase == 1, "reaching the skip point wins the stage")
		_ok(game.best_rank.has(idx), "a rank was recorded")
		var expect_unlock: int = mini(idx + 1, LevelData.count())
		_ok(game.unlocked >= expect_unlock, "stage %d unlocked" % expect_unlock)
		await _drop(lv)

		# -------------------------------------------- losing on suspicion ---
		# Stand in a watcher's face and hold there. Suspicion should climb to
		# full (or the watcher simply grabs him) — either way the stage is lost.
		lv = await _load_level(idx)
		var watcher = null      # untyped on purpose: naming the Npc class here would
		                        # pull npc.gd into this entry script's compile pass,
		                        # which happens before the autoloads exist
		for n in lv.get_tree().get_nodes_in_group("npc"):
			var npc = n
			if npc.stats["catch"] == "lose" and watcher == null:
				watcher = npc
			elif npc.stats["catch"] == "dialogue":
				# Drop the monitors for this check: their excuse dialogue pauses
				# the tree waiting for a human, which would stall the run.
				npc.queue_free()
		await _steps(2)
		_ok(watcher != null, "stage has a watcher that can catch you")
		if watcher != null:
			var peak := 0.0
			for i in 320:
				if lv.phase != 0:
					break
				if i < 200:
					# pin him in the cone so the test does not depend on patrol timing
					lv.player.global_position = watcher.global_position \
						+ Vector2(watcher.facing * 36.0, 0)
				peak = maxf(peak, lv.suspicion)
				await physics_frame
			_ok(peak > 45.0, "standing in the open drives suspicion up (peaked %.0f%%)" % peak)
			_ok(lv.phase == 2, "being watched in the open loses the stage")
		await _drop(lv)

		# ------------------------ a watcher must calm down once you are gone ---
		lv = await _load_level(idx)
		var w = null
		for n in lv.get_tree().get_nodes_in_group("npc"):
			if n.stats["catch"] == "lose" and w == null:
				w = n
			elif n.stats["catch"] == "dialogue":
				n.queue_free()
		await _steps(2)
		if w != null:
			# let him notice
			for i in 150:
				lv.player.global_position = w.global_position + Vector2(w.facing * 40.0, 0)
				lv.suspicion = 0.0
				if w.awareness > 0.9:
					break
				await physics_frame
			var noticed: bool = w.awareness > 0.5 or w.state != 0
			_ok(noticed, "watcher notices the player (awareness %.2f)" % w.awareness)

			# now vanish and let him search, then settle
			lv.player.set_hidden(true)
			var calmed := false
			var took := 0.0
			for i in 1200:
				lv.suspicion = 0.0
				await physics_frame
				took += 1.0 / 60.0
				# 0 is Npc.State.PATROL, spelled as a literal so this entry
				# script never pulls npc.gd into its own compile pass.
				if w.state == 0 and w.awareness <= 0.15:
					calmed = true
					break
			_ok(calmed, "watcher returns to patrolling after losing him (%.1fs)" % took)
			_ok(lv.phase == 0, "no loss was triggered while he searched")
		await _drop(lv)

		# -------------------------------------------- losing on the clock ---
		lv = await _load_level(idx)
		lv.time_left = 0.02
		await _steps(12)
		_ok(lv.phase == 2, "running out of time away from the goal loses")
		await _drop(lv)

		# ------------------------------- walking back into the classroom ----
		var cr: Array = spec.get("classroom", [])
		if cr.size() == 4:
			lv = await _load_level(idx)
			lv.player.global_position = Vector2(
				(cr[0] + cr[2] / 2.0) * 16.0, (cr[1] + cr[3] - 1) * 16.0)
			await _steps(12)
			_ok(lv.phase == 2, "entering the classroom loses instantly")
			await _drop(lv)

	# ---------------------------------------------------------- progression --
	print("\n=== progression ===")
	_ok(game.unlocked == LevelData.count(), "every stage unlocked after clearing all")
	_ok(game.all_cleared(), "all_cleared() reports true")
	_ok(game.rank_for(60.0, 60.0, 0, 0.0) == "S", "a flawless clear grades S")
	_ok(game.rank_for(1.0, 60.0, 3, 99.0) == "C", "a scrappy clear grades C")
	game.wipe_save()

	print("\n%d checks, %d failed" % [_checks, _fails.size()])
	for f in _fails:
		print("  FAILED: ", f)
	quit(1 if _fails.size() > 0 else 0)
