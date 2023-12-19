class_name Sanitizer

const SCENE_PATTERN: String = "^res://[a-zA-Z0-9_]+[a-zA-Z0-9_/]*\\.tscn$"

static func sanitize_scene_path(unsafe_path: String) -> String:
	var regex: RegEx = RegEx.create_from_string(SCENE_PATTERN)
	
	while unsafe_path.contains("../"):
		unsafe_path = unsafe_path.replace("../", "")
	
	var result: RegExMatch = regex.search(unsafe_path)
	if result != null:
		return result.get_string()
	return ""
