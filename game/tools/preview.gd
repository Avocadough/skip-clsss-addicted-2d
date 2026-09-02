extends SceneTree
# Composites the generated art onto one zoomed sheet so it can be eyeballed.
func _initialize() -> void:
	var dir := ProjectSettings.globalize_path("res://assets/sprites/")
	var names := ["char_not", "char_teacher", "char_monitor", "char_guard", "char_mind"]
	var scale := 4
	var out := Image.create(176 * scale, 24 * scale * names.size() + 40 * scale, false, Image.FORMAT_RGBA8)
	out.fill(Color8(0x18, 0x14, 0x24))
	var y := 0
	for n in names:
		var im := Image.load_from_file(dir + n + ".png")
		im.resize(im.get_width() * scale, im.get_height() * scale, Image.INTERPOLATE_NEAREST)
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(0, y))
		y += im.get_height()
	# tiles + a row of items underneath
	var t := Image.load_from_file(dir + "tiles_hallway.png")
	t.resize(t.get_width() * scale, t.get_height() * scale, Image.INTERPOLATE_NEAREST)
	out.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i(0, y))
	y += t.get_height() + 8
	var items := ["item_nursecard", "item_coin", "item_notebook", "item_key", "item_wetsign",
		"item_hoodie", "icon_eye", "icon_bag", "icon_star", "prop_cctv", "prop_crate"]
	var x := 0
	for n in items:
		var im := Image.load_from_file(dir + n + ".png")
		im.resize(im.get_width() * scale, im.get_height() * scale, Image.INTERPOLATE_NEAREST)
		out.blit_rect(im, Rect2i(Vector2i.ZERO, im.get_size()), Vector2i(x, y))
		x += im.get_width() + 4
	out.save_png(ProjectSettings.globalize_path("res://preview.png"))
	print("preview written")
	quit()
