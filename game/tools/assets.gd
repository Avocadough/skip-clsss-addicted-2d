extends SceneTree
# ============================================================================
#  Asset generator for "Skip Class Addicted / เสพติดการโดดเรียน!"
#  Draws every sprite in the game from compact pixel grids so the whole game
#  shares one palette and one art style.
#  Run:  Godot.exe --headless --path game --script res://tools/assets.gd
# ============================================================================

const OUT := "res://assets/sprites/"

# ---------------------------------------------------------------- palette ---
const INK        := Color8(0x24, 0x1f, 0x31)
const SKIN       := Color8(0xf2, 0xc8, 0xa2)
const SKIN_D     := Color8(0xd4, 0xa1, 0x7b)
const WHITE      := Color8(0xf5, 0xf1, 0xe6)
const CREAM      := Color8(0xf2, 0xe2, 0xb6)
const CREAM_D    := Color8(0xd9, 0xc2, 0x8e)
const PURPLE     := Color8(0xb6, 0xa6, 0xe0)
const PURPLE_D   := Color8(0x7d, 0x6c, 0xad)
const BLUEGRAY   := Color8(0x7d, 0x94, 0xb5)
const BLUEGRAY_D := Color8(0x53, 0x67, 0x87)
const NAVY       := Color8(0x3b, 0x4a, 0x6b)
const PINK       := Color8(0xf0, 0xb8, 0xc8)
const PINK_D     := Color8(0xc7, 0x8b, 0x9e)
const GREEN      := Color8(0x7f, 0xa0, 0x8a)
const GREEN_D    := Color8(0x56, 0x74, 0x60)
const RED        := Color8(0xd8, 0x6b, 0x6b)
const YELLOW     := Color8(0xf2, 0xd0, 0x6b)
const HAIR       := Color8(0x36, 0x2c, 0x40)
const HAIR_BR    := Color8(0x5a, 0x40, 0x38)
const SHOE       := Color8(0x3a, 0x31, 0x47)
const WOOD       := Color8(0x9c, 0x74, 0x53)
const WOOD_D     := Color8(0x74, 0x53, 0x3c)
const STONE      := Color8(0x6f, 0x6a, 0x82)
const STONE_D    := Color8(0x4e, 0x4a, 0x60)
const METAL      := Color8(0x8e, 0x99, 0xa8)
const METAL_D    := Color8(0x62, 0x6b, 0x7a)

# ------------------------------------------------------------ pixel grids ---
# Head occupies rows 0..8, torso rows 9..14, legs rows 15..21 of a 16x24 cell.

const HEAD := [
	"................",
	".....HHHHHH.....",
	"....HHHHHHHH....",
	"....HHSSSSHH....",
	"....HSSSSSSH....",
	"....HSESSESH....",
	"....HSSSSSSH....",
	".....SSSSSS.....",
	"......SSSS......",
]

const HAIR_LONG := [
	"................",
	"................",
	"................",
	"................",
	"...H........H...",
	"...H........H...",
	"...H........H...",
	"...HH......HH...",
	"................",
]

const HAIR_BUN := [
	"......HHHH......",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
	"................",
]

const CAP := [
	"................",
	"....CCCCCCCC....",
	"...CCCCCCCCCC...",
	"..CCCCCCCCCCCC..",
	"................",
	"................",
	"................",
	"................",
	"................",
]

const ARM_NEUTRAL := [
	"...TTTTTTTTTT...",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTR..",
	"..STTTTTTTTTTS..",
	"...TTTTTTTTTT...",
]
const ARM_A := [
	"..RTTTTTTTTTT...",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTR..",
	"..STTTTAATTTTR..",
	"...TTTTTTTTTTS..",
	"...TTTTTTTTTT...",
]
const ARM_B := [
	"...TTTTTTTTTTR..",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTS..",
	"..STTTTTTTTTT...",
	"...TTTTTTTTTT...",
]
const ARM_WIDE := [
	"..RTTTTTTTTTTR..",
	".STTTTTAATTTTTS.",
	"..RTTTTAATTTTR..",
	"..RTTTTAATTTTR..",
	"...TTTTTTTTTT...",
	"...TTTTTTTTTT...",
]

const LEG_STAND := [
	"...PPPPPPPPPP...",
	"....PPP..PPP....",
	"....PPP..PPP....",
	"....PPP..PPP....",
	"....PPP..PPP....",
	"...OOOO..OOOO...",
	"................",
]
const LEG_WALK_A := [
	"...PPPPPPPPPP...",
	"...PPPP..PPP....",
	"..PPP.....PPP...",
	"..PPP.....PPP...",
	".PPP......PPP...",
	".OOOO.....OOOO..",
	"................",
]
const LEG_WALK_PASS := [
	"...PPPPPPPPPP...",
	"....PPPPPPPP....",
	"....PPP..PPP....",
	"....PPP..PPP....",
	"....PPP..PPP....",
	"...OOOO..OOOO...",
	"................",
]
const LEG_WALK_B := [
	"...PPPPPPPPPP...",
	"....PPP..PPPP...",
	"...PPP.....PPP..",
	"...PPP.....PPP..",
	"...PPP......PPP.",
	"..OOOO.....OOOO.",
	"................",
]
const LEG_JUMP := [
	"...PPPPPPPPPP...",
	"...PPPP..PPPP...",
	"..PPP......PPP..",
	"..PPP......PPP..",
	"..OOOO....OOOO..",
	"................",
	"................",
]
const LEG_FALL := [
	"...PPPPPPPPPP...",
	"...PPP....PPP...",
	"..PPP......PPP..",
	"..PPP......PPP..",
	".PPP........PPP.",
	".OOOO......OOOO.",
	"................",
]
const LEG_CROUCH := [
	"................",
	"................",
	"................",
	"................",
	"................",
	"..PPPPPPPPPPPP..",
	".OOO......OOO...",
]

# ------------------------------------------------------------- primitives ---
func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

func blit(img: Image, grid: Array, ox: int, oy: int, pal: Dictionary) -> void:
	for y in grid.size():
		var row: String = grid[y]
		for x in row.length():
			var ch := row[x]
			if ch == "." or not pal.has(ch):
				continue
			px(img, ox + x, oy + y, pal[ch])

func new_img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

## Darkens the last pixel of every horizontal run: cheap, readable shading.
func shade(img: Image, region := Rect2i()) -> void:
	if region.size == Vector2i.ZERO:
		region = Rect2i(0, 0, img.get_width(), img.get_height())
	var src := Image.create_from_data(img.get_width(), img.get_height(), false, img.get_format(), img.get_data())
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var right_empty := x + 1 >= region.end.x or src.get_pixel(x + 1, y).a < 0.5
			var below_empty := y + 1 >= region.end.y or src.get_pixel(x, y + 1).a < 0.5
			if right_empty or below_empty:
				img.set_pixel(x, y, c.darkened(0.18))

## Wraps opaque pixels in a 1px ink border (expects 1px of slack around art).
func outline(img: Image, col: Color = INK, region := Rect2i()) -> void:
	if region.size == Vector2i.ZERO:
		region = Rect2i(0, 0, img.get_width(), img.get_height())
	var src := Image.create_from_data(img.get_width(), img.get_height(), false, img.get_format(), img.get_data())
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			if src.get_pixel(x, y).a >= 0.5:
				continue
			for d in dirs:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx < region.position.x or ny < region.position.y or nx >= region.end.x or ny >= region.end.y:
					continue
				if src.get_pixel(nx, ny).a >= 0.5:
					img.set_pixel(x, y, col)
					break

func save_png(img: Image, name: String) -> void:
	var path := OUT + name + ".png"
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("save failed: %s (%d)" % [path, err])
	else:
		print("  wrote ", name, ".png  ", img.get_width(), "x", img.get_height())

# ============================================================================
#  Characters
# ============================================================================
const CELL_W := 16
const CELL_H := 24
const FRAME_COUNT := 11

# frame -> [head_dy, arm_pose, arm_dy, leg_pose]
func _frame_recipe(i: int) -> Array:
	match i:
		0: return [0, ARM_NEUTRAL, 9, LEG_STAND]        # idle A
		1: return [1, ARM_NEUTRAL, 10, LEG_STAND]       # idle B (breath)
		2: return [0, ARM_A, 9, LEG_WALK_A]             # walk 1
		3: return [1, ARM_NEUTRAL, 10, LEG_WALK_PASS]   # walk 2
		4: return [0, ARM_B, 9, LEG_WALK_B]             # walk 3
		5: return [1, ARM_NEUTRAL, 10, LEG_WALK_PASS]   # walk 4
		6: return [0, ARM_WIDE, 9, LEG_JUMP]            # jump
		7: return [0, ARM_WIDE, 9, LEG_FALL]            # fall
		8: return [6, ARM_NEUTRAL, 14, LEG_CROUCH]      # crouch A
		9: return [7, ARM_NEUTRAL, 15, LEG_CROUCH]      # crouch B
		_: return [0, ARM_WIDE, 9, LEG_STAND]           # alert / caught

func make_character(pal: Dictionary, hair_style: String = "short") -> Image:
	var sheet := new_img(CELL_W * FRAME_COUNT, CELL_H)
	for i in FRAME_COUNT:
		var r := _frame_recipe(i)
		var head_dy: int = r[0]
		var f := new_img(CELL_W, CELL_H)
		blit(f, r[3], 0, 15, pal)
		blit(f, r[1], 0, r[2], pal)
		blit(f, HEAD, 0, head_dy, pal)
		match hair_style:
			"long": blit(f, HAIR_LONG, 0, head_dy, pal)
			"bun":  blit(f, HAIR_BUN, 0, head_dy, pal)
			"cap":  blit(f, CAP, 0, head_dy, pal)
		shade(f)
		outline(f)
		sheet.blit_rect(f, Rect2i(0, 0, CELL_W, CELL_H), Vector2i(i * CELL_W, 0))
	return sheet

func draw_characters() -> void:
	print("characters:")
	# น็อต - the player. Thai school uniform: white shirt, navy shorts.
	save_png(make_character({
		"H": HAIR_BR, "S": SKIN, "E": INK, "T": WHITE, "R": WHITE,
		"A": CREAM_D, "P": NAVY, "O": SHOE,
	}), "char_not")

	# มายด์ - best friend / helper NPC.
	save_png(make_character({
		"H": HAIR, "S": SKIN, "E": INK, "T": WHITE, "R": WHITE,
		"A": PINK, "P": NAVY, "O": SHOE,
	}, "long"), "char_mind")

	# ครูประจำชั้น - patrolling homeroom teacher.
	save_png(make_character({
		"H": HAIR, "S": SKIN, "E": INK, "T": PURPLE, "R": PURPLE_D,
		"A": PURPLE_D, "P": STONE_D, "O": SHOE,
	}, "bun"), "char_teacher")

	# หัวหน้าห้อง - the class monitor who reports you.
	save_png(make_character({
		"H": HAIR, "S": SKIN, "E": INK, "T": WHITE, "R": WHITE,
		"A": PINK_D, "P": PINK_D, "O": SHOE,
	}, "long"), "char_monitor")

	# รปภ. - the guard at the back gate (final boss).
	save_png(make_character({
		"H": HAIR, "S": SKIN_D, "E": INK, "T": BLUEGRAY, "R": BLUEGRAY_D,
		"A": YELLOW, "P": NAVY, "O": SHOE, "C": BLUEGRAY_D,
	}, "cap"), "char_guard")

	# บรรณารักษ์ - librarian (level 3).
	save_png(make_character({
		"H": HAIR, "S": SKIN, "E": INK, "T": GREEN, "R": GREEN_D,
		"A": GREEN_D, "P": STONE_D, "O": SHOE,
	}, "bun"), "char_librarian")

	# ครูพละ - the PE coach (level 4).
	save_png(make_character({
		"H": HAIR, "S": SKIN_D, "E": INK, "T": RED, "R": RED,
		"A": WHITE, "P": NAVY, "O": SHOE, "C": RED,
	}, "cap"), "char_coach")

	# นักเรียนทั่วไป - background students that clutter the cafeteria.
	save_png(make_character({
		"H": HAIR, "S": SKIN, "E": INK, "T": WHITE, "R": WHITE,
		"A": BLUEGRAY, "P": NAVY, "O": SHOE,
	}), "char_student")
	save_png(make_character({
		"H": HAIR_BR, "S": SKIN_D, "E": INK, "T": WHITE, "R": WHITE,
		"A": GREEN, "P": NAVY, "O": SHOE,
	}, "long"), "char_student2")

# ============================================================================
#  Tiles  (16x16, laid out in one horizontal strip; must tile seamlessly so
#  they are drawn procedurally and never outlined)
# ============================================================================
const TS := 16
const TILE_NAMES := [
	"floor_top", "floor_fill", "wall", "wall_top", "platform", "ladder",
	"bg_wall", "bg_window", "bg_tilewall", "grass_top", "dirt_fill", "fence",
]

func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in range(y, y + h):
		for i in range(x, x + w):
			px(img, i, j, c)

func hline(img: Image, x: int, y: int, w: int, c: Color) -> void:
	rect(img, x, y, w, 1, c)

func vline(img: Image, x: int, y: int, h: int, c: Color) -> void:
	rect(img, x, y, 1, h, c)

## Deterministic speckle so builds are reproducible.
func speckle(img: Image, x: int, y: int, w: int, h: int, c: Color, seed_v: int, density: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for j in range(y, y + h):
		for i in range(x, x + w):
			if rng.randi() % 100 < density:
				px(img, i, j, c)

func draw_tile(img: Image, ox: int, name: String) -> void:
	match name:
		"floor_top":
			rect(img, ox, 0, TS, 3, CREAM)
			hline(img, ox, 3, TS, CREAM_D)
			rect(img, ox, 4, TS, 12, STONE_D)
			speckle(img, ox, 5, TS, 11, STONE, 11, 8)
			vline(img, ox, 4, 12, STONE_D.darkened(0.25))
		"floor_fill":
			rect(img, ox, 0, TS, TS, STONE_D)
			speckle(img, ox, 0, TS, TS, STONE, 22, 8)
			vline(img, ox, 0, TS, STONE_D.darkened(0.25))
			hline(img, ox, 0, TS, STONE_D.darkened(0.15))
		"wall":
			rect(img, ox, 0, TS, TS, STONE)
			# offset brick courses
			hline(img, ox, 0, TS, STONE_D)
			hline(img, ox, 8, TS, STONE_D)
			vline(img, ox, 0, 8, STONE_D)
			vline(img, ox + 8, 8, 8, STONE_D)
			speckle(img, ox, 1, TS, 15, STONE.lightened(0.08), 33, 6)
		"wall_top":
			rect(img, ox, 0, TS, 3, CREAM_D)
			rect(img, ox, 3, TS, 13, STONE)
			hline(img, ox, 8, TS, STONE_D)
			vline(img, ox + 8, 8, 8, STONE_D)
			vline(img, ox, 3, 5, STONE_D)
		"platform":
			rect(img, ox, 0, TS, 2, WOOD)
			hline(img, ox, 2, TS, WOOD_D)
			hline(img, ox, 3, TS, WOOD_D.darkened(0.3))
			vline(img, ox, 0, 3, WOOD_D)
		"ladder":
			rect(img, ox + 2, 0, 2, TS, METAL)
			rect(img, ox + 12, 0, 2, TS, METAL)
			rect(img, ox + 3, 2, 10, 2, METAL_D)
			rect(img, ox + 3, 10, 10, 2, METAL_D)
		"bg_wall":
			# Flat plaster with a faint vertical seam. Any horizontal detail
			# here would repeat every 16px and read as stripes across the wall,
			# so the wainscot line is painted once by the level builder instead.
			var base := Color8(0x45, 0x3d, 0x5b)
			rect(img, ox, 0, TS, TS, base)
			vline(img, ox, 0, TS, base.darkened(0.12))
			speckle(img, ox, 0, TS, TS, base.lightened(0.05), 44, 6)
			speckle(img, ox, 0, TS, TS, base.darkened(0.08), 45, 4)
		"bg_window":
			rect(img, ox, 0, TS, TS, BLUEGRAY.lightened(0.25))
			rect(img, ox, 0, TS, 2, WOOD_D)
			rect(img, ox, 14, TS, 2, WOOD_D)
			vline(img, ox, 0, TS, WOOD_D)
			vline(img, ox + 15, 0, TS, WOOD_D)
			vline(img, ox + 7, 2, 12, WOOD_D)
			hline(img, ox + 1, 8, 14, WOOD_D)
			# a soft highlight streak so glass reads as glass
			for k in 5:
				px(img, ox + 2 + k, 3 + k, Color(1, 1, 1, 0.35))
		"bg_tilewall":
			rect(img, ox, 0, TS, TS, CREAM.darkened(0.12))
			hline(img, ox, 0, TS, CREAM_D.darkened(0.2))
			hline(img, ox, 8, TS, CREAM_D.darkened(0.2))
			vline(img, ox, 0, TS, CREAM_D.darkened(0.2))
			vline(img, ox + 8, 0, TS, CREAM_D.darkened(0.2))
		"grass_top":
			rect(img, ox, 0, TS, TS, WOOD_D.darkened(0.15))
			rect(img, ox, 0, TS, 4, GREEN)
			hline(img, ox, 4, TS, GREEN_D)
			# ragged blades along the top edge
			for i in TS:
				if i % 3 == 0:
					px(img, ox + i, 0, GREEN.lightened(0.2))
					px(img, ox + i, 5, GREEN_D)
			speckle(img, ox, 6, TS, 10, WOOD_D.darkened(0.35), 55, 10)
		"dirt_fill":
			rect(img, ox, 0, TS, TS, WOOD_D.darkened(0.15))
			speckle(img, ox, 0, TS, TS, WOOD_D.darkened(0.4), 66, 12)
			speckle(img, ox, 0, TS, TS, WOOD.darkened(0.3), 67, 6)
		"fence":
			# Drawn into its own cell-sized buffer so the diagonals cannot
			# spill into neighbouring tiles of the atlas.
			var cell := new_img(TS, TS)
			for i in range(-TS, TS * 2, 8):
				for k in TS:
					px(cell, i + k, k, METAL_D)
					px(cell, i + TS - k, k, METAL_D)
			rect(cell, 0, 0, 1, TS, METAL)
			rect(cell, 15, 0, 1, TS, METAL)
			img.blit_rect(cell, Rect2i(0, 0, TS, TS), Vector2i(ox, 0))

func draw_tiles() -> void:
	print("tiles:")
	var img := new_img(TS * TILE_NAMES.size(), TS)
	for i in TILE_NAMES.size():
		draw_tile(img, i * TS, TILE_NAMES[i])
	save_png(img, "tiles")

# ============================================================================
#  Props, items, icons
# ============================================================================
func disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx := x - cx
			var dy := y - cy
			if dx * dx + dy * dy <= r * r:
				px(img, x, y, c)

func ring(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			var dx := x - cx
			var dy := y - cy
			var d := dx * dx + dy * dy
			if d <= r * r and d > (r - 1.2) * (r - 1.2):
				px(img, x, y, c)

func tri_down(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	for j in h:
		var inset := int(float(j) / h * (w / 2.0))
		rect(img, x + inset, y + j, w - inset * 2, 1, c)

func finish(img: Image) -> Image:
	shade(img)
	outline(img)
	return img

# ------------------------------------------------------------------ props ---
func prop_locker() -> Image:
	var img := new_img(16, 28)
	rect(img, 1, 1, 14, 26, METAL_D)
	rect(img, 2, 2, 12, 24, METAL)
	hline(img, 2, 13, 12, METAL_D)          # split between two doors
	for d in 2:
		var top := 3 + d * 13
		for v in 3:
			rect(img, 5, top + v * 2, 6, 1, METAL_D)   # vent slits
		rect(img, 11, top + 7, 1, 3, METAL_D)          # handle
	return finish(img)

func prop_desk() -> Image:
	var img := new_img(28, 17)
	rect(img, 1, 2, 26, 3, WOOD)            # desktop
	hline(img, 1, 5, 26, WOOD_D)
	rect(img, 3, 6, 3, 10, WOOD_D)          # legs
	rect(img, 22, 6, 3, 10, WOOD_D)
	rect(img, 6, 7, 16, 4, WOOD.darkened(0.15))   # under-shelf: the hiding gap
	return finish(img)

func prop_table() -> Image:
	var img := new_img(32, 16)
	rect(img, 1, 2, 30, 3, CREAM_D)
	hline(img, 1, 5, 30, CREAM_D.darkened(0.3))
	rect(img, 4, 6, 3, 9, METAL_D)
	rect(img, 25, 6, 3, 9, METAL_D)
	rect(img, 7, 9, 18, 2, METAL_D)
	return finish(img)

func prop_bookshelf() -> Image:
	var img := new_img(32, 32)
	rect(img, 1, 1, 30, 30, WOOD_D)
	rect(img, 2, 2, 28, 28, WOOD.darkened(0.35))
	var spines := [RED, CREAM, GREEN, PURPLE, BLUEGRAY, PINK, YELLOW]
	for shelf in 3:
		var sy := 3 + shelf * 9
		var x := 4
		var n := 0
		while x < 27:
			var w: int = 2 + (n + shelf) % 3
			var h: int = 6 - (n % 2)
			rect(img, x, sy + (7 - h), w, h, spines[(n * 3 + shelf) % spines.size()])
			x += w + 1
			n += 1
		hline(img, 2, sy + 7, 28, WOOD_D)
	return finish(img)

func prop_bush() -> Image:
	var img := new_img(22, 15)
	disc(img, 7, 9, 5.5, GREEN_D)
	disc(img, 14, 9, 5.5, GREEN_D)
	disc(img, 11, 7, 6.0, GREEN)
	rect(img, 2, 12, 18, 2, GREEN_D)
	return finish(img)

func prop_crate() -> Image:
	var img := new_img(16, 16)
	rect(img, 0, 0, 16, 16, WOOD)
	rect(img, 1, 1, 14, 14, WOOD.lightened(0.08))
	hline(img, 1, 1, 14, WOOD_D)
	hline(img, 1, 14, 14, WOOD_D)
	vline(img, 1, 1, 14, WOOD_D)
	vline(img, 14, 1, 14, WOOD_D)
	for k in 13:
		px(img, 2 + k, 2 + k, WOOD_D)
		px(img, 14 - k, 2 + k, WOOD_D)
	return finish(img)

func prop_trashcan() -> Image:
	var img := new_img(14, 16)
	rect(img, 2, 3, 10, 12, METAL_D)
	rect(img, 3, 4, 8, 10, METAL)
	rect(img, 1, 1, 12, 2, METAL_D)
	rect(img, 6, 0, 2, 1, METAL_D)
	for k in 3:
		vline(img, 4 + k * 2, 5, 8, METAL_D)
	return finish(img)

func prop_vending() -> Image:
	var img := new_img(18, 30)
	rect(img, 1, 1, 16, 28, METAL_D)
	rect(img, 2, 3, 10, 20, BLUEGRAY.lightened(0.3))   # glass front
	var drinks := [RED, GREEN, YELLOW, PINK]
	for r_i in 3:
		for c_i in 3:
			rect(img, 3 + c_i * 3, 5 + r_i * 6, 2, 4, drinks[(r_i + c_i) % 4])
	rect(img, 13, 4, 3, 8, CREAM_D)      # keypad
	rect(img, 3, 24, 8, 3, METAL.darkened(0.4))   # dispenser slot
	return finish(img)

func prop_door() -> Image:
	var img := new_img(18, 30)
	rect(img, 1, 1, 16, 28, WOOD_D)
	rect(img, 2, 2, 14, 26, WOOD)
	rect(img, 4, 4, 10, 8, BLUEGRAY.lightened(0.25))   # window pane
	hline(img, 4, 8, 10, WOOD_D)
	rect(img, 13, 17, 2, 3, YELLOW)                    # handle
	rect(img, 4, 15, 10, 10, WOOD.darkened(0.12))
	return finish(img)

func prop_door_locked() -> Image:
	var img := prop_door()
	# chunky padlock over the middle so "locked" reads at a glance
	rect(img, 6, 15, 6, 5, METAL_D)
	rect(img, 7, 16, 4, 3, YELLOW)
	rect(img, 7, 12, 4, 3, METAL_D)
	px(img, 8, 13, WOOD)
	px(img, 9, 13, WOOD)
	return img

func prop_cctv() -> Image:
	var img := new_img(20, 14)
	rect(img, 1, 1, 3, 5, METAL_D)        # wall mount
	rect(img, 4, 3, 2, 2, METAL_D)
	rect(img, 5, 2, 11, 7, METAL)         # body
	rect(img, 5, 2, 11, 2, METAL.lightened(0.15))
	rect(img, 16, 4, 3, 4, METAL_D)       # lens housing
	rect(img, 17, 5, 2, 2, Color8(0xff, 0x6b, 0x6b))
	rect(img, 7, 0, 4, 2, METAL_D)        # antenna nub
	return finish(img)

func prop_exit_sign() -> Image:
	var img := new_img(22, 12)
	rect(img, 1, 1, 20, 10, GREEN_D)
	rect(img, 2, 2, 18, 8, GREEN)
	# running-person glyph
	rect(img, 5, 3, 2, 2, WHITE)
	rect(img, 4, 5, 4, 3, WHITE)
	rect(img, 3, 8, 2, 2, WHITE)
	rect(img, 7, 8, 2, 2, WHITE)
	# arrow
	rect(img, 11, 5, 6, 2, WHITE)
	rect(img, 15, 3, 2, 2, WHITE)
	rect(img, 15, 7, 2, 2, WHITE)
	rect(img, 17, 4, 2, 4, WHITE)
	return finish(img)

func prop_bell() -> Image:
	var img := new_img(18, 18)
	rect(img, 8, 1, 2, 2, METAL_D)
	disc(img, 9, 9, 6.0, YELLOW)
	rect(img, 3, 9, 12, 4, YELLOW)
	rect(img, 2, 13, 14, 2, YELLOW.darkened(0.25))
	rect(img, 8, 15, 2, 2, YELLOW.darkened(0.4))
	disc(img, 7, 7, 2.0, YELLOW.lightened(0.35))
	return finish(img)

func prop_whiteboard() -> Image:
	var img := new_img(40, 22)
	rect(img, 1, 1, 38, 20, GREEN_D.darkened(0.35))
	rect(img, 2, 2, 36, 16, GREEN_D)
	rect(img, 1, 18, 38, 3, WOOD_D)
	for k in 4:
		rect(img, 5 + k * 8, 5, 5, 1, WHITE.darkened(0.15))
		rect(img, 5 + k * 8, 9, 4, 1, WHITE.darkened(0.15))
	return finish(img)

func prop_clock() -> Image:
	var img := new_img(16, 16)
	disc(img, 7.5, 7.5, 7.0, CREAM)
	ring(img, 7.5, 7.5, 7.0, INK)
	rect(img, 7, 3, 1, 5, INK)
	rect(img, 8, 7, 4, 1, INK)
	return finish(img)

func prop_safe_zone() -> Image:
	# The pulsing marker painted on a level's goal tile.
	var img := new_img(24, 24)
	ring(img, 11.5, 11.5, 10.0, GREEN)
	ring(img, 11.5, 11.5, 7.0, GREEN_D)
	rect(img, 10, 4, 3, 12, GREEN)
	rect(img, 6, 11, 11, 3, GREEN)
	return img

# ------------------------------------------------------------------ items ---
func item_nursecard() -> Image:
	var img := new_img(16, 16)
	rect(img, 2, 4, 12, 9, WHITE)
	rect(img, 2, 4, 12, 2, RED)
	rect(img, 4, 8, 5, 1, STONE_D)          # tiny text lines
	rect(img, 4, 10, 4, 1, STONE_D)
	rect(img, 10, 7, 2, 5, RED)             # red cross
	rect(img, 9, 9, 4, 2, RED)
	return finish(img)

func item_coin() -> Image:
	var img := new_img(16, 16)
	disc(img, 7.5, 8.0, 6.0, YELLOW.darkened(0.25))
	disc(img, 7.5, 8.0, 5.0, YELLOW)
	disc(img, 5.5, 6.0, 1.5, YELLOW.lightened(0.4))
	rect(img, 5, 6, 1, 5, YELLOW.darkened(0.45))     # a stamped "10"
	rect(img, 8, 6, 3, 1, YELLOW.darkened(0.45))
	rect(img, 8, 10, 3, 1, YELLOW.darkened(0.45))
	vline(img, 8, 7, 3, YELLOW.darkened(0.45))
	vline(img, 10, 7, 3, YELLOW.darkened(0.45))
	return finish(img)

func item_notebook() -> Image:
	var img := new_img(16, 16)
	rect(img, 3, 2, 10, 13, BLUEGRAY_D)
	rect(img, 5, 3, 8, 11, WHITE)
	for k in 4:
		rect(img, 3, 4 + k * 3, 3, 1, METAL)         # spiral rings
	rect(img, 7, 5, 5, 1, RED)                       # name line
	rect(img, 7, 8, 4, 1, STONE_D)
	rect(img, 7, 10, 5, 1, STONE_D)
	return finish(img)

func item_key() -> Image:
	var img := new_img(16, 16)
	ring(img, 4.5, 6.0, 3.2, YELLOW)
	rect(img, 6, 8, 8, 2, YELLOW)                    # shaft
	rect(img, 11, 10, 2, 2, YELLOW)                  # teeth
	rect(img, 8, 10, 2, 2, YELLOW)
	return finish(img)

func item_wetsign() -> Image:
	# Build the triangle pointing down, then flip so the sign stands on its base.
	var tmp := new_img(16, 16)
	tri_down(tmp, 2, 2, 12, 12, YELLOW)
	var img := new_img(16, 16)
	for y in 16:
		for x in 16:
			var c := tmp.get_pixel(x, 15 - y)
			if c.a > 0.5:
				img.set_pixel(x, y, c)
	rect(img, 7, 6, 2, 5, INK)                       # exclamation mark
	rect(img, 7, 12, 2, 2, INK)
	rect(img, 2, 14, 12, 1, YELLOW.darkened(0.3))
	return finish(img)

func item_hoodie() -> Image:
	var img := new_img(16, 16)
	disc(img, 8, 5, 4.0, PURPLE_D)                   # hood
	disc(img, 8, 6, 2.6, PURPLE_D.darkened(0.35))    # hood opening
	rect(img, 4, 7, 8, 7, PURPLE)                    # body
	rect(img, 1, 7, 3, 5, PURPLE_D)                  # sleeves
	rect(img, 12, 7, 3, 5, PURPLE_D)
	rect(img, 7, 8, 2, 4, PURPLE_D)                  # zip
	return finish(img)

# ------------------------------------------------------------------ icons ---
func icon_eye() -> Image:
	var img := new_img(16, 16)
	for x in range(1, 15):
		var t := float(x - 8) / 7.0
		var h: int = int(round(5.0 * (1.0 - t * t)))
		if h > 0:
			rect(img, x, 8 - h, 1, h * 2, WHITE)
	disc(img, 8, 8, 3.0, BLUEGRAY_D)
	disc(img, 8, 8, 1.6, INK)
	px(img, 7, 7, WHITE)
	return finish(img)

func icon_bag() -> Image:
	var img := new_img(16, 16)
	rect(img, 5, 2, 6, 3, RED.darkened(0.3))         # shoulder strap
	rect(img, 6, 3, 4, 2, Color(0, 0, 0, 0))
	rect(img, 3, 5, 10, 9, RED)
	rect(img, 3, 8, 10, 3, RED.darkened(0.25))       # flap
	rect(img, 7, 9, 2, 2, YELLOW)                    # buckle
	return finish(img)

func icon_star() -> Image:
	var img := new_img(16, 16)
	var pts := PackedVector2Array([
		Vector2(8, 1), Vector2(10, 6), Vector2(15, 6), Vector2(11, 9),
		Vector2(13, 14), Vector2(8, 11), Vector2(3, 14), Vector2(5, 9),
		Vector2(1, 6), Vector2(6, 6),
	])
	for y in 16:
		for x in 16:
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				img.set_pixel(x, y, YELLOW)
	return finish(img)

func bubble(glyph: String, tint: Color) -> Image:
	var img := new_img(14, 18)
	rect(img, 1, 1, 12, 12, tint)
	rect(img, 0, 3, 14, 8, tint)
	rect(img, 3, 0, 8, 14, tint)
	rect(img, 5, 13, 4, 3, tint)                     # tail
	rect(img, 6, 15, 2, 2, tint)
	match glyph:
		"!":
			rect(img, 6, 3, 2, 6, INK)
			rect(img, 6, 10, 2, 2, INK)
		"?":
			rect(img, 5, 3, 4, 2, INK)
			rect(img, 8, 4, 2, 3, INK)
			rect(img, 6, 6, 3, 2, INK)
			rect(img, 6, 8, 2, 1, INK)
			rect(img, 6, 10, 2, 2, INK)
		"z":
			rect(img, 5, 4, 5, 2, INK)
			rect(img, 7, 6, 2, 2, INK)
			rect(img, 5, 8, 2, 2, INK)
			rect(img, 5, 10, 5, 2, INK)
	return finish(img)

func fx_dust() -> Image:
	var sheet := new_img(8 * 4, 8)
	var radii := [1.2, 2.2, 3.0, 3.4]
	var alphas := [1.0, 0.85, 0.55, 0.25]
	for i in 4:
		var c := CREAM
		c.a = alphas[i]
		disc(sheet, i * 8 + 4, 4, radii[i], c)
	return sheet

# ------------------------------------------------------------ backgrounds ---
func draw_backgrounds() -> void:
	print("backgrounds:")
	# Early-morning sky: deep purple up top fading to warm cream at the horizon,
	# which is the palette the design document calls for.
	var sky := new_img(480, 270)
	var top := Color8(0x3a, 0x2f, 0x55)
	var mid := Color8(0x8b, 0x6a, 0x94)
	var low := Color8(0xe0, 0x9c, 0x9c)
	var horizon := Color8(0xf2, 0xe2, 0xb6)
	for y in 270:
		var t := float(y) / 269.0
		var c: Color
		if t < 0.45:
			c = top.lerp(mid, t / 0.45)
		elif t < 0.78:
			c = mid.lerp(low, (t - 0.45) / 0.33)
		else:
			c = low.lerp(horizon, (t - 0.78) / 0.22)
		hline(sky, 0, y, 480, c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for i in 14:
		var cx := rng.randf_range(0, 480)
		var cy := rng.randf_range(20, 120)
		var r := rng.randf_range(6, 16)
		var cc := Color(1, 1, 1, rng.randf_range(0.10, 0.22))
		disc(sky, cx, cy, r, cc)
		disc(sky, cx + r * 0.8, cy + 2, r * 0.7, cc)
		disc(sky, cx - r * 0.8, cy + 2, r * 0.7, cc)
	save_png(sky, "bg_sky")

	# Distant school buildings (slowest parallax layer).
	var far := new_img(480, 140)
	var body := Color8(0x50, 0x45, 0x6b)
	for bx in range(0, 480, 96):
		var bh: int = 70 + (bx / 96) % 3 * 16
		rect(far, bx + 4, 140 - bh, 88, bh, body)
		rect(far, bx + 2, 140 - bh - 4, 92, 5, body.darkened(0.2))
		for wy in range(140 - bh + 10, 132, 16):
			for wx in range(bx + 12, bx + 86, 14):
				var lit: bool = ((wx + wy) / 7) % 3 == 0
				rect(far, wx, wy, 8, 9, YELLOW if lit else Color8(0x35, 0x2d, 0x4a))
	save_png(far, "bg_school")

	# Tree line just behind the play field.
	var trees := new_img(480, 70)
	rng.seed = 4242
	for i in 40:
		var tx := rng.randf_range(-10, 490)
		var r2 := rng.randf_range(10, 20)
		var sc := GREEN_D.darkened(rng.randf_range(0.15, 0.45))
		disc(trees, tx, 70 - r2 * 0.6, r2, sc)
	rect(trees, 0, 60, 480, 10, GREEN_D.darkened(0.5))
	save_png(trees, "bg_trees")

# ============================================================================
func draw_props_and_items() -> void:
	print("props:")
	save_png(prop_locker(), "prop_locker")
	save_png(prop_desk(), "prop_desk")
	save_png(prop_table(), "prop_table")
	save_png(prop_bookshelf(), "prop_bookshelf")
	save_png(prop_bush(), "prop_bush")
	save_png(prop_crate(), "prop_crate")
	save_png(prop_trashcan(), "prop_trashcan")
	save_png(prop_vending(), "prop_vending")
	save_png(prop_door(), "prop_door")
	save_png(prop_door_locked(), "prop_door_locked")
	save_png(prop_cctv(), "prop_cctv")
	save_png(prop_exit_sign(), "prop_exit_sign")
	save_png(prop_bell(), "prop_bell")
	save_png(prop_whiteboard(), "prop_whiteboard")
	save_png(prop_clock(), "prop_clock")
	save_png(prop_safe_zone(), "prop_safe_zone")
	print("items:")
	save_png(item_nursecard(), "item_nursecard")
	save_png(item_coin(), "item_coin")
	save_png(item_notebook(), "item_notebook")
	save_png(item_key(), "item_key")
	save_png(item_wetsign(), "item_wetsign")
	save_png(item_hoodie(), "item_hoodie")
	print("icons + fx:")
	save_png(icon_eye(), "icon_eye")
	save_png(icon_bag(), "icon_bag")
	save_png(icon_star(), "icon_star")
	save_png(bubble("!", CREAM), "fx_alert")
	save_png(bubble("?", CREAM), "fx_question")
	save_png(bubble("z", PURPLE), "fx_calm")
	save_png(fx_dust(), "fx_dust")

func _initialize() -> void:
	print("=== generating art for Skip Class Addicted ===")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	draw_characters()
	draw_tiles()
	draw_props_and_items()
	draw_backgrounds()
	print("=== done ===")
	quit()
