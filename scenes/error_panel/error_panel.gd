class_name ErrorPanel extends Panel

const ErrorType = EditorEnums.ErrorType;


@onready var lbl_message: Label = %lbl_message

func _ready() -> void:
	set_message(ErrorType.DIFFER_SIZES_AMONG_FILES);


func set_message(msg_type: ErrorType):
	
	match msg_type:
		ErrorType.SIZE_NOT_EQUAL:
			lbl_message.text = "The tile has not the same height and width. That's an invalid configuration";
			
		ErrorType.DIFFER_SIZES_AMONG_FILES:
			lbl_message.text = "There are different tile size among the import detected, that's an invalid configuration.";

	

func _on_btn_okay_pressed() -> void:
	EditorSignals.new_texture.emit();
	hide();
