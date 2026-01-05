extends Node2D

enum Terrain {WATER, LAND}

const ISLAND_SIZE = 50
const SMOOTHING_ITERS = 5
const MARGINS = 3
const NOISE_FREQ = 0.02
const LAND_TOLER = 0.25

static func generate_map(seedStr: String) -> TileMapLayer:
	var map := {}
	var seedValue = seedStr.hash()
	
	map = await generate_island(seedValue)
	
	for i in range(SMOOTHING_ITERS):
		map = smooth_island(map)
	
	var tileMap = apply_to_tilemap(map)
	
	return tileMap

static func generate_island(seedValue: int) -> Dictionary:
	var islandMap = {}
	
	# Generate noise, texture, and apply
	var noise = FastNoiseLite.new()
	noise.seed = seedValue
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = NOISE_FREQ
	noise.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	noise.fractal_octaves = 6
	
	var texture = NoiseTexture2D.new()
	texture.height = ISLAND_SIZE
	texture.width = ISLAND_SIZE
	texture.noise = noise
	
	await texture.changed
	var image = texture.get_image()
	
	# Generate mask
	var maskImage := Image.create(ISLAND_SIZE, ISLAND_SIZE, false, Image.FORMAT_L8)
	
	var center := Vector2(ISLAND_SIZE * 0.5, ISLAND_SIZE * 0.5)
	var radius := ISLAND_SIZE * 0.5
	
	for x in ISLAND_SIZE:
		for y in ISLAND_SIZE:
			var dist := center.distance_to(Vector2(x, y)) / radius
			var val = clamp(1.0 - dist, 0, 1.0)
			maskImage.set_pixel(x, y, Color(val, val, val))
	
	# Generate map
	seed(seedValue)
	for x in range(ISLAND_SIZE):
		for y in range(ISLAND_SIZE):
			var tile = Vector2(x,y)
			
			# Determine Margins
			var closestEdge = [x,y,ISLAND_SIZE-x,ISLAND_SIZE-y].min()
			if closestEdge < MARGINS:
				islandMap[tile] = Terrain.WATER
				pass
			
			# Otherwise, create noisemap
			var noisePixel = image.get_pixel(x,y)
			var maskPixel = maskImage.get_pixel(x,y)
			islandMap[tile] = Terrain.WATER if LAND_TOLER > noisePixel.r * maskPixel.r else Terrain.LAND
	
	return islandMap


static func smooth_island(map: Dictionary) -> Dictionary:
	for x in range(ISLAND_SIZE):
		for y in range(ISLAND_SIZE):
			var tile = Vector2(x,y)
			
			# Check for valid connections
			var directions = [-1,1]
			var validCorners = []
			for dx in directions:
				for dy in directions:
					var edge1 = tile + Vector2(dx,0)
					var edge2 = tile + Vector2(0,dy)
					var corner = tile + Vector2(dx,dy)
					var cornerTiles = [edge1, edge2, corner]
					var validNeighbors = 0
					for i in cornerTiles:
						if map.has(i) and map[i] == Terrain.LAND:
							validNeighbors += 1
					if validNeighbors == 3: validCorners.append(Vector2(dx,dy))
			
			if len(validCorners) == 0:
				map[tile] = Terrain.WATER
			elif len(validCorners) > 2:
				map[tile] = Terrain.LAND
			elif len(validCorners) == 2:
				if validCorners[0] + validCorners[1] == Vector2(0,0):
					map[tile] = Terrain.WATER
			
	return map


static func apply_to_tilemap(map: Dictionary) -> TileMapLayer:
	var tileMap := TileMapLayer.new()
	tileMap.tile_set = load("res://assets/terrain/terrain.tres")
	var gridArr = []
	var landArr = []
	for coordinate in map:
		gridArr.append(coordinate)
		if map[coordinate] == Terrain.LAND:
			landArr.append(coordinate)
	tileMap.set_cells_terrain_connect(gridArr, 0, Terrain.WATER, false)
	tileMap.set_cells_terrain_connect(landArr, 0, Terrain.LAND, false)
	return tileMap
