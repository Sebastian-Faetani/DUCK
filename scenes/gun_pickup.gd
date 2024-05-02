extends Area3D

@onready var SHOTGUN = preload("res://scenes/bread_shotgun.tscn")

func _on_body_entered(body):
	if body.is_in_group("player"):
		if !body.carried_guns.has(SHOTGUN):
			body.carried_guns.append(SHOTGUN)
			$CollisionShape3D.disabled = true
			$Sprite3D.hide()
		else:
			pass
