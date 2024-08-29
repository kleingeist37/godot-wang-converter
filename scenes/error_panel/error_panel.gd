class_name ErrorPanel extends Panel


var message := "There are different tile size among the import detected, that's an invalid configuration!";

@onready var lbl_message: Label = %lbl_message

func _ready() -> void:
	set_message(message);


func set_message(msg: String):
	lbl_message.text= msg;
	

func _on_btn_okay_pressed() -> void:
	EditorSignals.new_texture.emit();
	hide();
