class_name PlayerInfos extends Control

@onready var healthbar: ProgressBar = $Healthbar

func _ready():
	pass

#
# Player signals
#

func _on_player_health_update(_old_health: float, new_health: float, max_health: float):
	healthbar.max_value = max_health
	healthbar.value = new_health
