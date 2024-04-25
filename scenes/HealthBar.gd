extends TextureProgressBar

@export var player: Player

func _ready():
	player.healthChanged.connect(update)
	update()
	
func update():
	value = player.CURRENT_PLAYER_HEALTH * 100 / player.MAX_PLAYER_HEALTH
	
