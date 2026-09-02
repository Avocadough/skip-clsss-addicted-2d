extends SceneTree
## Per-stage art: a tile atlas and parallax backdrop for each of the five
## settings, so the hallway, cafeteria, library, sports field and back gate
## each read as their own place instead of sharing one wall.
##   Godot.exe --headless --path game --script res://tools/themes.gd

const OUT := "res://assets/sprites/"
const TS := 16

# ---------------------------------------------------------------- palettes --
# Every stage gets the same twelve tile roles painted in its own colours, so
# level.gd can swap atlases without knowing anything about the art.
const THEMES := {
	"hallway": {
		"outdoor": false,
		"floor_light": "e8e2cf", "floor_edge": "cfc6ac",
		"floor_fill": "4e4a60", "floor_speck": "6f6a82",
		"wall": "453d5b", "wall_speck": "51486b",
		"wainscot": "d8cfa8", "wainscot_line": "b3a882",
		"platform": "9c7453", "platform_dark": "74533c",
		"ladder": "8e99a8", "ladder_dark": "626b7a",
		"glass": "a9c4de", "frame": "74533c",
		"ground_top": "7fa08a", "ground_dark": "56745f", "ground_fill": "5a4636",
		"fence": "8e99a8",
	},
	"cafeteria": {
		"outdoor": false,
		"floor_light": "f0cfa4", "floor_edge": "cb9f6f",
		"floor_fill": "544138", "floor_speck": "6f584a",
		"wall": "4f4032", "wall_speck": "5e4c3a",
		"wainscot": "d99f6b", "wainscot_line": "ac7a4d",
		"platform": "8e99a8", "platform_dark": "626b7a",
		"ladder": "8e99a8", "ladder_dark": "626b7a",
		"glass": "cbdcc9", "frame": "8a6a45",
		"ground_top": "7fa08a", "ground_dark": "56745f", "ground_fill": "5a4636",
		"fence": "8e99a8",
	},
	"library": {
		"outdoor": false,
		"floor_light": "8a6240", "floor_edge": "6b4a30",
		"floor_fill": "3a2f2a", "floor_speck": "52423a",
		"wall": "3b3a2e", "wall_speck": "47463a",
		"wainscot": "7a5a3c", "wainscot_line": "5c4229",
		"platform": "9c7453", "platform_dark": "6b4a30",
		"ladder": "9c7453", "ladder_dark": "6b4a30",
		"glass": "d8c9a0", "frame": "5c4229",
		"ground_top": "7fa08a", "ground_dark": "56745f", "ground_fill": "5a4636",
		"fence": "8e99a8",
	},
	"field": {
		"outdoor": true,
		"floor_light": "e8e2cf", "floor_edge": "cfc6ac",
		"floor_fill": "4e4a60", "floor_speck": "6f6a82",
		"wall": "453d5b", "wall_speck": "51486b",
		"wainscot": "d8cfa8", "wainscot_line": "b3a882",
		"platform": "9c7453", "platform_dark": "74533c",
		"ladder": "a8b2bd", "ladder_dark": "6f7885",
		"glass": "a9c4de", "frame": "74533c",
		"ground_top": "7fb069", "ground_dark": "5c8a4c", "ground_fill": "7a5a3c",
		"fence": "a8b2bd",
	},
	"gate": {
		"outdoor": true,
		"floor_light": "cdb9a6", "floor_edge": "a3907f",
		"floor_fill": "4a3f4e", "floor_speck": "5e5162",
		"wall": "413650", "wall_speck": "4d4060",
		"wainscot": "b8a48f", "wainscot_line": "927f6c",
		"platform": "8a6a52", "platform_dark": "634b39",
		"ladder": "7d8794", "ladder_dark": "58606b",
		"glass": "e8b98a", "frame": "634b39",
		"ground_top": "5c7a5a", "ground_dark": "435c45", "ground_fill": "4a3a30",
		"fence": "7d8794",
	},
}

const TILE_ROLES := [
	"floor_top", "floor_fill", "wall", "wall_top", "platform", "ladder",
	"bg_wall", "bg_tilewall", "grass_top", "dirt_fill", "fence",
]

# -------------------------------------------------------------- primitives --
func C(th: Dictionary, key: String) -> Color:
	return Color(th[key])

func new_img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		if c.a >= 1.0:
			img.set_pixel(x, y, c)
		elif c.a > 0.0:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))

func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			px(img, i, j, c)

func hline(img: Image, x: int, y: int, w: int, c: Color) -> void:
	rect(img, x, y, w, 1, c)

func vline(img: Image, x: int, y: int, h: int, c: Color) -> void:
	rect(img, x, y, 1, h, c)

func disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r:
				px(img, x, y, c)

func speckle(img: Image, x: int, y: int, w: int, h: int, c: Color, sd: int, density: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = sd
	for j in range(y, y + h):
		for i in range(x, x + w):
			if rng.randi() % 100 < density:
				px(img, i, j, c)

func save_png(img: Image, name: String) -> void:
	var err := img.save_png(ProjectSettings.globalize_path(OUT + name + ".png"))
	if err != OK:
		push_error("save failed: %s" % name)
	else:
		print("  %-28s %dx%d" % [name + ".png", img.get_width(), img.get_height()])

# ------------------------------------------------------------------ tiles ---
func draw_tile(img: Image, ox: int, role: String, th: Dictionary) -> void:
	match role:
		"floor_top":
			rect(img, ox, 0, TS, 3, C(th, "floor_light"))
			hline(img, ox, 3, TS, C(th, "floor_edge"))
			rect(img, ox, 4, TS, 12, C(th, "floor_fill"))
			speckle(img, ox, 5, TS, 11, C(th, "floor_speck"), 11, 8)
			vline(img, ox, 4, 12, C(th, "floor_fill").darkened(0.25))
		"floor_fill":
			rect(img, ox, 0, TS, TS, C(th, "floor_fill"))
			speckle(img, ox, 0, TS, TS, C(th, "floor_speck"), 22, 8)
			vline(img, ox, 0, TS, C(th, "floor_fill").darkened(0.25))
			hline(img, ox, 0, TS, C(th, "floor_fill").darkened(0.15))
		"wall", "wall_top":
			var base := C(th, "wall")
			rect(img, ox, 0, TS, TS, base)
			if role == "wall_top":
				rect(img, ox, 0, TS, 3, C(th, "wainscot"))
			hline(img, ox, 8, TS, base.darkened(0.2))
			vline(img, ox, 0, 8, base.darkened(0.2))
			vline(img, ox + 8, 8, 8, base.darkened(0.2))
		"platform":
			rect(img, ox, 0, TS, 2, C(th, "platform"))
			hline(img, ox, 2, TS, C(th, "platform_dark"))
			hline(img, ox, 3, TS, C(th, "platform_dark").darkened(0.3))
			vline(img, ox, 0, 3, C(th, "platform_dark"))
		"ladder":
			rect(img, ox + 2, 0, 2, TS, C(th, "ladder"))
			rect(img, ox + 12, 0, 2, TS, C(th, "ladder"))
			rect(img, ox + 3, 2, 10, 2, C(th, "ladder_dark"))
			rect(img, ox + 3, 10, 10, 2, C(th, "ladder_dark"))
		"bg_wall":
			var w := C(th, "wall")
			rect(img, ox, 0, TS, TS, w)
			vline(img, ox, 0, TS, w.darkened(0.12))
			speckle(img, ox, 0, TS, TS, C(th, "wall_speck"), 44, 6)
			speckle(img, ox, 0, TS, TS, w.darkened(0.08), 45, 4)
		"bg_tilewall":
			var t := C(th, "wainscot")
			rect(img, ox, 0, TS, TS, t)
			hline(img, ox, 0, TS, C(th, "wainscot_line"))
			hline(img, ox, 8, TS, C(th, "wainscot_line"))
			vline(img, ox, 0, TS, C(th, "wainscot_line"))
			vline(img, ox + 8, 0, TS, C(th, "wainscot_line"))
		"grass_top":
			rect(img, ox, 0, TS, TS, C(th, "ground_fill"))
			rect(img, ox, 0, TS, 4, C(th, "ground_top"))
			hline(img, ox, 4, TS, C(th, "ground_dark"))
			for i in TS:
				if i % 3 == 0:
					px(img, ox + i, 0, C(th, "ground_top").lightened(0.2))
					px(img, ox + i, 5, C(th, "ground_dark"))
			speckle(img, ox, 6, TS, 10, C(th, "ground_fill").darkened(0.3), 55, 10)
		"dirt_fill":
			rect(img, ox, 0, TS, TS, C(th, "ground_fill"))
			speckle(img, ox, 0, TS, TS, C(th, "ground_fill").darkened(0.35), 66, 12)
			speckle(img, ox, 0, TS, TS, C(th, "ground_fill").lightened(0.12), 67, 6)
		"fence":
			var cell := new_img(TS, TS)
			for i in range(-TS, TS * 2, 8):
				for k in TS:
					px(cell, i + k, k, C(th, "fence").darkened(0.3))
					px(cell, i + TS - k, k, C(th, "fence").darkened(0.3))
			rect(cell, 0, 0, 1, TS, C(th, "fence"))
			rect(cell, 15, 0, 1, TS, C(th, "fence"))
			img.blit_rect(cell, Rect2i(0, 0, TS, TS), Vector2i(ox, 0))

func draw_tiles() -> void:
	print("tile atlases:")
	for name in THEMES:
		var th: Dictionary = THEMES[name]
		var img := new_img(TS * TILE_ROLES.size(), TS)
		for i in TILE_ROLES.size():
			draw_tile(img, i * TS, TILE_ROLES[i], th)
		save_png(img, "tiles_" + name)

# ================================================================ backdrops ==
#  Indoor stages get one architectural strip that scrolls slower than the
#  world, sitting between the flat wall colour and the play field. Outdoor
#  stages get a sky, a far silhouette and a near tree line.
#  Everything is 480 wide so it tiles across any level length.
# =============================================================================

func vgrad(img: Image, stops: Array) -> void:
	## stops: [[position 0..1, "rrggbb"], ...] painted top to bottom.
	var h := img.get_height()
	for y in h:
		var t := float(y) / maxf(h - 1, 1)
		var c := Color(stops[0][1])
		for i in range(stops.size() - 1):
			var a: float = stops[i][0]
			var b: float = stops[i + 1][0]
			if t >= a and t <= b:
				c = Color(stops[i][1]).lerp(Color(stops[i + 1][1]), (t - a) / maxf(b - a, 0.001))
				break
			if t > b:
				c = Color(stops[i + 1][1])
		hline(img, 0, y, img.get_width(), c)

func puff(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	disc(img, cx, cy, r, c)
	disc(img, cx - r * 0.85, cy + r * 0.25, r * 0.7, c)
	disc(img, cx + r * 0.85, cy + r * 0.25, r * 0.7, c)
	disc(img, cx + r * 0.35, cy - r * 0.45, r * 0.6, c)

# ------------------------------------------------------------- hallway -----
func deco_hallway(th: Dictionary) -> Image:
	var img := new_img(480, 160)
	var wall := C(th, "wall")
	# pilasters
	for x in range(24, 480, 112):
		rect(img, x, 0, 12, 160, wall.lightened(0.10))
		vline(img, x, 0, 160, wall.lightened(0.18))
		vline(img, x + 11, 0, 160, wall.darkened(0.15))
	# classroom doorways
	for x in [70, 300]:
		rect(img, x, 62, 48, 98, C(th, "frame"))
		rect(img, x + 4, 68, 40, 92, wall.darkened(0.45))
		rect(img, x + 8, 74, 32, 22, C(th, "glass").darkened(0.25))   # door window
		rect(img, x + 38, 118, 3, 5, Color("f2d06b"))                  # handle
	# notice board with pinned papers
	rect(img, 190, 70, 76, 50, Color("8a6a45"))
	rect(img, 193, 73, 70, 44, Color("6f5637"))
	var papers := ["f5f1e6", "f0b8c8", "b6a6e0", "f2d06b"]
	for i in 6:
		rect(img, 198 + (i % 3) * 22, 78 + (i / 3) * 20, 17, 15, Color(papers[i % 4]))
	# hanging lamps with a warm pool of light
	for x in range(60, 480, 120):
		vline(img, x, 0, 12, Color("3a3147"))
		rect(img, x - 9, 12, 19, 5, Color("d9c28e"))
		rect(img, x - 6, 17, 13, 2, Color("f2e2b6"))
		disc(img, x, 24, 13, Color(1.0, 0.93, 0.7, 0.10))
		disc(img, x, 20, 8, Color(1.0, 0.93, 0.7, 0.10))
	return img

# ----------------------------------------------------------- cafeteria -----
func deco_cafeteria(th: Dictionary) -> Image:
	var img := new_img(480, 160)
	var wall := C(th, "wall")
	# bunting across the top
	var flags := ["e0776f", "f2d06b", "8fc99a", "7d94b5", "f0b8c8"]
	for i in range(0, 24):
		var x := i * 20
		var y := 6 + int(abs(sin(i * 0.9)) * 4)
		hline(img, x, y, 20, Color("5e4c3a"))
		for k in 9:
			rect(img, x + 4 + k / 2, y + 1 + k, 11 - k, 1, Color(flags[i % 5]))
	# menu boards
	for i in 3:
		var bx := 40 + i * 150
		rect(img, bx, 26, 96, 44, Color("2f2a24"))
		rect(img, bx + 3, 29, 90, 38, Color("3f382e"))
		for r in 4:
			rect(img, bx + 9, 35 + r * 8, 40 + (r * 13) % 34, 2, Color("d9c28e"))
	# pendant lamps
	for x in range(85, 480, 100):
		vline(img, x, 0, 22, Color("3a3147"))
		rect(img, x - 7, 22, 15, 8, Color("e0776f"))
		rect(img, x - 4, 30, 9, 2, Color("f2e2b6"))
		disc(img, x, 38, 15, Color(1.0, 0.88, 0.6, 0.11))
	# serving counter along the bottom
	rect(img, 0, 108, 480, 6, Color("a8b2bd"))
	rect(img, 0, 114, 480, 46, Color("8e99a8").darkened(0.35))
	for x in range(0, 480, 24):
		vline(img, x, 114, 46, Color("626b7a").darkened(0.2))
	# trays and cups on top
	for i in range(0, 12):
		var tx := 14 + i * 40
		rect(img, tx, 100, 20, 8, Color(["d9c28e", "e0776f", "8fc99a"][i % 3]))
		rect(img, tx + 2, 98, 16, 2, Color("f5f1e6"))
	return img

# ------------------------------------------------------------- library -----
func deco_library(th: Dictionary) -> Image:
	var img := new_img(480, 160)
	var spines := ["e0776f", "f2e2b6", "8fc99a", "b6a6e0", "7d94b5", "f0b8c8", "f2d06b", "c88a5a"]
	var n := 0
	for bx in range(0, 480, 120):
		if bx == 240:
			# leave a gap for an arched window between the stacks
			rect(img, bx + 26, 26, 68, 96, C(th, "frame"))
			rect(img, bx + 30, 30, 60, 88, C(th, "glass"))
			for k in 30:
				disc(img, bx + 60, 34 + k, 30 - k * 0.55, C(th, "glass"))
			vline(img, bx + 59, 30, 88, C(th, "frame"))
			hline(img, bx + 30, 72, 60, C(th, "frame"))
			continue
		# a tall bookcase
		rect(img, bx + 6, 14, 108, 146, Color("5c4229"))
		rect(img, bx + 10, 18, 100, 138, Color("3a2c1c"))
		for shelf in 5:
			var sy := 22 + shelf * 27
			var x := bx + 14
			while x < bx + 106:
				var w: int = 4 + (n * 7) % 5
				var h: int = 18 - (n % 4) * 2
				if x + w > bx + 106:
					break
				rect(img, x, sy + (22 - h), w, h, Color(spines[n % spines.size()]))
				rect(img, x, sy + (22 - h), w, 1, Color(spines[n % spines.size()]).lightened(0.25))
				x += w + 1
				n += 1
			rect(img, bx + 10, sy + 22, 100, 3, Color("5c4229"))
	# a reading lamp glow drifting over the stacks
	disc(img, 180, 40, 22, Color(1.0, 0.9, 0.62, 0.09))
	disc(img, 400, 52, 26, Color(1.0, 0.9, 0.62, 0.07))
	return img

# ---------------------------------------------------------- outdoor sky ----
func sky_field() -> Image:
	var img := new_img(480, 270)
	vgrad(img, [[0.0, "4a93c8"], [0.45, "8cc4e0"], [0.8, "cfe8f0"], [1.0, "eef3e2"]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 771
	for i in 9:
		var cx := rng.randf_range(0, 480)
		var cy := rng.randf_range(24, 110)
		puff(img, cx, cy, rng.randf_range(11, 22), Color(1, 1, 1, 0.55))
	disc(img, 402, 44, 17, Color(1.0, 0.98, 0.86, 0.85))   # sun haze
	disc(img, 402, 44, 11, Color(1.0, 1.0, 0.94, 0.9))
	return img

func sky_gate() -> Image:
	var img := new_img(480, 270)
	vgrad(img, [[0.0, "2c2444"], [0.34, "6b4a7a"], [0.62, "c9738a"], [0.82, "f0a06a"], [1.0, "f7d79a"]])
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for i in 7:
		var cx := rng.randf_range(0, 480)
		var cy := rng.randf_range(30, 120)
		puff(img, cx, cy, rng.randf_range(10, 20), Color(1.0, 0.78, 0.72, 0.30))
	disc(img, 92, 46, 13, Color(1.0, 0.97, 0.88, 0.9))     # moon
	disc(img, 97, 43, 11, Color(0.17, 0.14, 0.27, 1.0))    # crescent bite
	for i in 40:                                            # early stars
		var sx := rng.randf_range(0, 480)
		var sy := rng.randf_range(0, 90)
		px(img, int(sx), int(sy), Color(1, 1, 1, rng.randf_range(0.25, 0.8)))
	return img

func far_field() -> Image:
	var img := new_img(480, 140)
	var body := Color("7c93b0")
	for bx in range(0, 480, 150):
		var bh := 74 + (bx / 150) % 2 * 18
		rect(img, bx + 8, 140 - bh, 132, bh, body)
		rect(img, bx + 4, 140 - bh - 5, 140, 6, body.darkened(0.18))
		for wy in range(140 - bh + 12, 134, 18):
			for wx in range(bx + 18, bx + 130, 16):
				rect(img, wx, wy, 9, 11, Color("dce7f0") if ((wx + wy) / 9) % 3 else Color("55688a"))
	# goal posts out on the field
	for gx in [60, 340]:
		rect(img, gx, 96, 3, 44, Color("e8eef2"))
		rect(img, gx + 62, 96, 3, 44, Color("e8eef2"))
		rect(img, gx, 96, 65, 3, Color("e8eef2"))
	return img

func far_gate() -> Image:
	var img := new_img(480, 140)
	var body := Color("42375c")
	for bx in range(0, 480, 118):
		var bh := 66 + (bx / 118) % 3 * 20
		rect(img, bx + 6, 140 - bh, 100, bh, body)
		rect(img, bx + 3, 140 - bh - 4, 106, 5, body.darkened(0.25))
		for wy in range(140 - bh + 10, 134, 16):
			for wx in range(bx + 14, bx + 100, 15):
				rect(img, wx, wy, 8, 10, Color("f2c06b") if ((wx + wy) / 7) % 3 == 0 else Color("332a49"))
	# telephone poles catching the last light
	for px_ in [150, 400]:
		rect(img, px_, 40, 4, 100, Color("2b2340"))
		rect(img, px_ - 12, 50, 28, 3, Color("2b2340"))
		rect(img, px_ - 9, 60, 22, 3, Color("2b2340"))
	return img

func trees(tint: Color, seed_v: int) -> Image:
	var img := new_img(480, 70)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in 44:
		var tx := rng.randf_range(-10, 490)
		var r := rng.randf_range(11, 21)
		puff(img, tx, 70 - r * 0.5, r, tint.darkened(rng.randf_range(0.0, 0.3)))
	rect(img, 0, 58, 480, 12, tint.darkened(0.42))
	return img

func cloud(size: int, seed_v: int) -> Image:
	var img := new_img(size, int(size * 0.62))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var r := size * 0.22
	puff(img, size * 0.5, size * 0.36, r, Color(1, 1, 1, 0.85))
	for i in 2:
		disc(img, rng.randf_range(r, size - r), size * 0.34 + rng.randf_range(-3, 3),
			r * rng.randf_range(0.55, 0.8), Color(1, 1, 1, 0.85))
	return img

func mote() -> Image:
	var img := new_img(4, 4)
	disc(img, 1.5, 1.5, 1.6, Color(1, 1, 1, 0.75))
	px(img, 1, 1, Color(1, 1, 1, 1.0))
	return img

func leaf() -> Image:
	var img := new_img(6, 6)
	disc(img, 2.5, 2.5, 2.4, Color("8fbf6a"))
	disc(img, 3.2, 2.0, 1.5, Color("a8d47f"))
	px(img, 2, 4, Color("5c7a3f"))
	return img

func draw_backdrops() -> void:
	print("backdrops:")
	save_png(deco_hallway(THEMES["hallway"]), "bg_hallway_deco")
	save_png(deco_cafeteria(THEMES["cafeteria"]), "bg_cafeteria_deco")
	save_png(deco_library(THEMES["library"]), "bg_library_deco")
	save_png(sky_field(), "bg_field_sky")
	save_png(far_field(), "bg_field_far")
	save_png(trees(Color("6b9e56"), 4242), "bg_field_trees")
	save_png(sky_gate(), "bg_gate_sky")
	save_png(far_gate(), "bg_gate_far")
	save_png(trees(Color("42563f"), 1717), "bg_gate_trees")
	print("drifting bits:")
	save_png(cloud(56, 11), "cloud_a")
	save_png(cloud(40, 22), "cloud_b")
	save_png(cloud(72, 33), "cloud_c")
	save_png(mote(), "fx_mote")
	save_png(leaf(), "fx_leaf")

func _initialize() -> void:
	print("=== per-stage art ===")
	draw_tiles()
	draw_backdrops()
	print("=== done ===")
	quit()
