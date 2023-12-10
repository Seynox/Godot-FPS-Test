class_name Rarity extends Node

const PROBABILITIES: Dictionary = {
	Level.COMMON: 65,
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

static func get_random_rarity() -> Rarity.Level:
	var random: int = randi_range(1, 101)
	var levels = Rarity.Level.values()
	levels.erase(Level.NONE)
	
	var result: Rarity.Level = Rarity.Level.COMMON
	for rarity in levels:
		var probability: int = Rarity.PROBABILITIES.get(rarity)
		if random <= probability:
			result = rarity
	
	return result
