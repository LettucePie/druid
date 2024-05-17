extends RichTextLabel

@export var manual_commit : String = "718477a32b999d4ac715259e1f7fe695e920f0f1"

# Called when the node enters the scene tree for the first time.
func _ready():
	var git_sha: String = ProjectSettings.get_setting("application/config/git_sha", "<unavailable>")
	print(git_sha)
	if git_sha == "<unavailable>":
		text += "[color=#ffffff88]" + manual_commit + "[/color]"
	else:
		text += "[color=#ffffff88]" + git_sha + "[/color]"
