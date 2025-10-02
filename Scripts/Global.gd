
extends Node

# Signal emitted when any character's HP changes
signal character_hp_changed(index: int, hp: int, max_hp: int, temp_hp: int)
# Signal emitted when a character is selected
signal character_selected(index: int)
# Signal emitted when a character is deselected
signal character_deselected()
# Signal emitted when initiative list is rebuilt
signal initiative_rebuilt()
