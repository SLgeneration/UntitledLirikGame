extends Node2D

const _MENU_EVENT: String = "Menu"
const _UI_CANCEL_EVENT: String = "ui_cancel"

var _player : Actor
var _menuOpen: bool = false
onready var cameraManager: CustomCamera2D

onready var _cam_Delimiter_Basement: CustomDelimiter2D = $LevelBackground/CameraPositions/Basement_Delimeter

onready var _gameMenu: PauseMenu = get_node("GUI/PauseMenu")

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent = get_parent()
	if(parent != null):
		var tree = parent.get_tree()
		var players = tree.get_nodes_in_group("Player")
		if(players.size() > 0):
			_player = players[0]
	assert(_player, "Player Node does not exist.")
	#assert(_camera, "Camera2D Node does not exist")
	cameraManager = CustomCamera2D.new(_player, true)
	cameraManager.limitCameraToDelimiter(_cam_Delimiter_Basement)
	_player.connect("health_changed", self, "_on_Player_health_changed")
	_player.connect("player_hit_enemy", cameraManager, "shake")
	_on_Player_health_changed(_player._health, _player._health, _player._maxHealth)


func _on_Player_health_changed(_oldHealth, newHealth, maxHealth):
	var healthBar = get_node("GUI/GameUI/healthBar")
	healthBar.Health = newHealth
	healthBar.MaxHealth = maxHealth
	healthBar.update_health()
