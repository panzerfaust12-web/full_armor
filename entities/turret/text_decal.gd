extends Decal

var decal_image:ImageTexture

func _ready() -> void:
	await RenderingServer.frame_post_draw
	var image = $SubViewport.get_texture().get_image()
	decal_image = ImageTexture.create_from_image(image)
	texture_albedo = decal_image
