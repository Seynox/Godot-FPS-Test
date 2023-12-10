class_name Rarity extends Node

const PROBABILITIES: Dictionary = {
	Level.COMMON: 60,
	Level.UNCOMMON: 30,
	Level.RARE: 9,
	Level.SECRET: 1,
	Level.NONE: 0
}

enum Level {
	NONE,
	COMMON,
	UNCOMMON,
	RARE,
	SECRET
}

static func get_random_rarity() -> Level:
	var max_range: int = 0
	var level_ranges: Dictionary = {}
	
	for level in PROBABILITIES.keys():
		var probability: int = PROBABILITIES.get(level)
		max_range += probability
		level_ranges[level] = max_range
	
	var random: int = randi_range(0, max_range - 1)
	
	for level: Level in level_ranges.keys():
		var range: int = level_ranges[level]
		if random < range:
			return level
	
	# Should not be possible to get here
	return Level.NONE
