extends Node

@onready var sfx:Node = $SFX
@onready var music:Node = $Music

var sfx_dict :={}
#var music_dict :={}

var music_play_list:Array[AudioStreamPlayer]

var is_background_playing:bool

signal music_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in sfx.get_children():
		if child is AudioStreamPlayer:
			sfx_dict[child.name.to_lower()] = child
	
	for child in music.get_children():
		if child is AudioStreamPlayer:
			child.finished.connect(on_music_finished)
	
	is_background_playing = true
	on_music_finished()

	
func sfx_play(SFXname:String) -> void :
	var sound_name := SFXname.to_lower()
	var player = sfx_dict.get(sound_name) as AudioStreamPlayer
	if player: player.play()
	else: printerr(SFXname," is not included in SFX")

func music_play(music_name:String) -> void:
	var player = music.get_node(music_name) as AudioStreamPlayer
	if player: player.play()
	else: printerr(music_name," is not included in SFX")

func play_music_random(index_list:Array[int]) -> void:
	var random_array = range(index_list.size())
	random_array.shuffle()
	is_background_playing = true
	for i:int in random_array:
		if music.get_children()[index_list[i]] is AudioStreamPlayer:
			music.get_children()[index_list[i]].play()
			await music.get_children()[index_list[i]].finished
	is_background_playing = false

func get_random_music_list() -> Array[AudioStreamPlayer]:
	var result:Array[AudioStreamPlayer]
	for child in music.get_children():
		if child is AudioStreamPlayer:
			result.append(child)
	return result

func on_music_finished()->void:
	if not is_background_playing:
		return
	if music_play_list.is_empty():
		music_play_list = get_random_music_list()
		music_play_list.shuffle()
	var audio = music_play_list.pop_back() as AudioStreamPlayer
	audio.play()
