extends RigidBody3D

func generate() -> void:
	for a in get_children():
		if a is MeshInstance3D:
			a.position = Vector3(0,0,0)
			a.rotation = Vector3(0,0,0)
			a.create_convex_collision(0,0)
	for a in find_children("*","CollisionShape3D",1,0):
		print("PENOR")
		add_child(a.duplicate())
	for a in find_children("*","StaticBody3D",1,0):
		a.queue_free()

func _on_timer_timeout() -> void:
	queue_free()
