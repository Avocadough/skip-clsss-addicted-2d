extends SceneTree
## Renders the 630x500 cover image itch.io wants for the game page, out of the
## same art the game runs on.
##   Godot.exe --path game --script res://tools/cover.gd
## Writes dist/cover.png beside the project. Needs a real window, so no
## --headless: the image comes off a SubViewport that has actually rendered.

const W := 630
const H := 500

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	# Loaded by path, not by class name: naming UI here would pull it, and the
	# autoloads it refers to, into the compile pass of this tool.
	var ui: GDScript = load("res://scripts/ui/ui.gd")

	var sub := SubViewport.new()
	sub.size = Vector2i(W, H)
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(sub)

	var page := Control.new()
	page.size = Vector2(W, H)
	sub.add_child(page)

	# ------------------------------------------------------------ backdrop --
	var sky := TextureRect.new()
	sky.texture = load("res://assets/sprites/bg_sky.png")
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sky.size = Vector2(W, H)
	page.add_child(sky)

	# Each strip keeps its own height so STRETCH_TILE only repeats sideways.
	for spec in [
		{"tex": "bg_school", "bottom": 118.0, "mod": Color(0.95, 0.92, 1.08)},
		{"tex": "bg_trees", "bottom": 62.0, "mod": Color(1.0, 1.08, 1.0)},
	]:
		var tex: Texture2D = load("res://assets/sprites/%s.png" % spec["tex"])
		var strip := TextureRect.new()
		strip.texture = tex
		strip.stretch_mode = TextureRect.STRETCH_TILE
		strip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		strip.size = Vector2(W, tex.get_height())
		strip.position = Vector2(0, H - float(spec["bottom"]) - tex.get_height())
		strip.modulate = spec["mod"]
		page.add_child(strip)

	var ground := ColorRect.new()
	ground.color = Color("332a4d")
	ground.position = Vector2(0, H - 62)
	ground.size = Vector2(W, 62)
	page.add_child(ground)

	var scrim := ColorRect.new()
	scrim.color = Color(0.07, 0.05, 0.12, 0.32)
	scrim.size = Vector2(W, H)
	page.add_child(scrim)

	# -------------------------------------------------------------- actors --
	# น็อต mid-stride on the left, a teacher looking the wrong way on the right.
	var runner := Sprite2D.new()
	runner.texture = load("res://assets/sprites/char_not.png")
	runner.hframes = 11
	runner.frame = 3
	runner.centered = false
	runner.offset = Vector2(-8, -22)
	runner.scale = Vector2(6.0, 6.0)
	runner.position = Vector2(112, H - 58)
	page.add_child(runner)

	var teacher := Sprite2D.new()
	teacher.texture = load("res://assets/sprites/char_teacher.png")
	teacher.hframes = 11
	teacher.frame = 0
	teacher.centered = false
	teacher.offset = Vector2(-8, -22)
	teacher.scale = Vector2(5.2, 5.2)
	teacher.flip_h = true
	teacher.position = Vector2(516, H - 58)
	page.add_child(teacher)

	# ---------------------------------------------------------------- text --
	var title: Label = ui.label("เสพติดการ\nโดดเรียน!", 58, ui.CREAM, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("outline_size", 14)
	title.add_theme_constant_override("line_spacing", -6)
	title.size = Vector2(W, 200)
	title.position = Vector2(0, 42)
	page.add_child(title)

	var sub_label: Label = ui.label("S K I P   C L A S S   A D D I C T E D", 18, ui.PURPLE, true)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.size = Vector2(W, 30)
	sub_label.position = Vector2(0, 208)
	page.add_child(sub_label)

	var tag: Label = ui.label("2D Pixel Art Stealth-Puzzle Platformer", 15, Color(0.86, 0.83, 0.92))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.size = Vector2(W, 26)
	tag.position = Vector2(0, 240)
	page.add_child(tag)

	for i in 12:
		await process_frame

	var out := ProjectSettings.globalize_path("res://").path_join("../dist/cover.png").simplify_path()
	var img := sub.get_texture().get_image()
	img.save_png(out)
	print("wrote ", out, "  ", img.get_width(), "x", img.get_height())
	quit()
