extends RigidBody3D

var impacted = false

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if $Lifetime.is_stopped():
		$Splosion.play()
		$Deadtimer.start()
		self.visible = false


func _on_body_entered(body: Node) -> void:
	if not impacted:
		$Splosion.play()
		linear_velocity = Vector3.ZERO
		impacted = true
	$Deadtimer.start()
	self.visible = false

func _on_deadtimer_timeout() -> void:
	queue_free()
