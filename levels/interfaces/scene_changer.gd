class_name SceneChanger extends Node

signal change_scene(new_scene: PackedScene)

@export var NEXT_SCENE: PackedScene

func _change_to_next_scene():
	change_scene.emit(NEXT_SCENE.instantiate())
