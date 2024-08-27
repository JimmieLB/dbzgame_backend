extends Node

var players = {}
var rooms = {}
var waiting_room = {}

const blank_room_template = {"map": 0, "players": {}, "attacks": {}} 

const PORT = 4820
const MAX_CLIENTS = 30

signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected

func _ready():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CLIENTS)
	if error:
		printerr(error)
	multiplayer.multiplayer_peer = peer
	player_connected.emit(1, {"NAME":"NAME"})
	
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.connection_failed.connect(_on_connected_fail)
	

func _net_tick():
	for room_id in rooms.keys():
		for player_id in rooms[room_id]["players"]:
			update_all_players.rpc_id(int(player_id), JSON.stringify(rooms[room_id]))


"""
	RECIEVERS
"""
@rpc("any_peer", "call_remote", "reliable")
func join_room(room_id, peer_id):
	if not rooms[room_id]:
		rooms[room_id] = blank_room_template.duplicate(true)
	rooms[room_id]["players"][peer_id] = {
		"position": {"x":0, "y":0}, 
		"velocity": {"x":0, "y":0}
		}
	waiting_room.erase(peer_id)
	players[str(peer_id)] = room_id

@rpc("any_peer", "call_remote", "reliable")
func send_create_room(name, peer_id):
	rooms[name] = blank_room_template.duplicate(true)
	join_room(name, peer_id)
	for plr in waiting_room.keys():
		get_rooms.rpc_id(int(plr), JSON.stringify(rooms.keys()))
	#print(rooms)

@rpc("any_peer", "call_remote", "reliable")
func get_rooms(peer_id):
	#print(rooms.keys())
	#get_rooms.rpc_id(int(peer_id),JSON.stringify(rooms.keys()))
	pass

@rpc("any_peer")
func update_player(room_id, peer_id, update):
	rooms[room_id]["players"][peer_id] = update

@rpc("any_peer")
func new_attack(room_id, attack_id, update):
	rooms[room_id]["attacks"][str(attack_id)] = JSON.parse_string(update)

@rpc("any_peer")
func remove_attack(room_id, attack_id):
	rooms[room_id]["attacks"].erase(attack_id)
"""
	SENDERS
"""
@rpc
func welcome_message():
	print("HELLO")

@rpc
func update_all_players(update):
	pass


func _on_player_connected(peer_id):
	print("Player " + str(peer_id) + " Connected")
	welcome_message.rpc_id(peer_id, peer_id)
	waiting_room[peer_id] = true
	get_rooms.rpc_id(int(peer_id), JSON.stringify(rooms.keys()))
	players[str(peer_id)] = ""

func _on_player_disconnected(id):
	var id_room = players[str(id)]
	players.erase(id)
	player_disconnected.emit(id)
	waiting_room.erase(id)
	print("Player " + str(id) + " Disconnected")
	if id_room == "":
		return
	rooms[id_room]["players"].erase(int(id))
	if rooms[id_room]["players"].keys().size() <= 0:
		rooms.erase(id_room)

func _on_connected_fail(peer_id):
	print("CONNECTION FAILED")



