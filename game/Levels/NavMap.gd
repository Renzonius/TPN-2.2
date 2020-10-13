tool
extends TileMap

#### Set abierto, cerrado y de todos los nodos (validos)
var all_set = []
var open_set = []
var closed_set = []
var optimal_way = []
var start_position : Vector2 = Vector2.ZERO # Posicion del player en el viewport
var end_position : Vector2 = Vector2.ZERO # Posicion del hongo en el viewport
var start_node: PathNode # Nodo correspondiente a la posicion del player
var end_node: PathNode # Nodo correspondiente a la posicion del hongo

#### Variables onready
onready var valid_tiles := get_used_cells() # posiciones/tiles validos

onready var open_tiles: TileMap = $NavOpen
onready var close_tiles: TileMap = $NavClose
onready var optimal_tiles: TileMap = $NavOptimal


#### Metodo que encuentra el camino entre el player y el hongo
func find_path(start, end) -> Array:
	start_position = pos_to_node(start) # convierto la posicion del player x,y en un vector c,f
	end_position = pos_to_node(end) # convierto la posicion del player x,y en un vector c,f
	
	
	init_grid(true)#inicia la grilla
	
	var select_node : PathNode = start_node
	
	while (select_node != end_node):
		select_node = find_closer_nodes(select_node)
		
	closed_set.append(end_node)
	
	optimal_way = optimal_path(closed_set)
	
	return optimal_way


#### Metodo que inicializa la grilla. Para cada tile valido crea un objeto de
#### PathNode y lo instancia con su posicion y la H
func init_grid(show: bool) -> void:
	for position in valid_tiles:
		var node := PathNode.new(null, position, (manhattan_distance(position, end_position)) * 10)
		all_set.append(node) # agrega el nodo a la lista de nodos validos
		
		set_start_end_nodes(node) # setea el nodo start y end
	# Para debug
#	if show:
#		for node in all_set:
#			print(node.print_node_data())

func optimal_path(closed_nodes : Array) -> Array:
	var real_optimus_way : Array
	var parent_array : Array
	var node_parent : PathNode
	closed_nodes.invert()
	parent_array.append(closed_nodes[0])
	node_parent = closed_nodes[0].parent
	
	var i:int = 1
	while (closed_nodes[i] != start_node):
		if(closed_nodes[i] == node_parent):
			parent_array.append(closed_nodes[i])
			node_parent = closed_nodes[i].parent
		i += 1
	
	parent_array.append(start_node)
	parent_array.invert()

		
	for node in parent_array:
		real_optimus_way.append(node_to_pos(node.position))

	return real_optimus_way
	
	
#### Metodo para setear nodos start y end
#### Pista: hay que usar el metodo de la clase PathNode "is_equal"
func set_start_end_nodes(node: PathNode) -> void:
	if(node.is_equal(start_position)):
		start_node = node #En este nodo esta Mario
	elif(node.is_equal(end_position)):
		end_node = node #En este nodo esta el Hongo
		


#### Metodo que detecta los nodos aledaños del nodo en el que estamos parados (current)
#### Pista: el current_node que le estamos pasando deberia cerrarse y el problema de nodos
#### aledaños se resuelve pensando en matrices (con las filas y columnas y una mascara)
func find_closer_nodes(current_node: PathNode) -> PathNode:
	var dummy_node: PathNode
	var redummy_node : Vector2
	var closer_node_list : Array
	var position_current : Array = [Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(-1,1), Vector2(-1,0),Vector2(-1,-1), 
									Vector2(0,-1), Vector2(1,-1)]
	if(current_node != start_node):
		open_set.erase(current_node)
	
	closed_set.append(current_node)

	for position_node in position_current:
		redummy_node = current_node.position - position_node
		closer_node_list.append(redummy_node)

	for node_position in closer_node_list:
		open_nodes(node_position, current_node)
	
	dummy_node = check_new_parent_node()
	
	return dummy_node

#		"* Manera de encontrar los nodos aledaños -
#		 * guardar los nodos dentro del array curret_node_list -
#		 * recorrer ese array aplicando el metodo open_node(posicion del nodo, nodo)"


#### Metodo que chequea si el nodo aledaño es valido. Para ser valido debe cumplir:
#### - Encontrarse en la lista de nodos validos -
#### - No encontrarse en la lista de nodos cerrados -
#### - No ser el mismo nodo en que estamos parados -
#### Si es valido se agrega a la lista de nodos abiertos y se le asigna el nodo padre
func open_nodes(node_position: Vector2, current_node: PathNode) -> void:
	var is_same_node : bool = current_node.is_equal(node_position)
	
	var near_node: PathNode
	for node in all_set:
		if node.is_equal(node_position):
			near_node = node
	if (near_node in all_set) and (not near_node in closed_set) and (not is_same_node) and (not  near_node in open_set):
		near_node.parent = current_node
		
		near_node.G =( near_node.parent.G + get_diagonal(near_node.position,current_node.position))
		near_node.F = near_node.H + near_node.G
		open_set.append(near_node)
	
	if near_node in open_set:
		var new_G = current_node.G + ( near_node.parent.G + get_diagonal(near_node.position, current_node.position))
		if (new_G < near_node.G):
			near_node.parent=current_node
			near_node.G = new_G
			near_node.F= near_node.G + near_node.H
	
	
#	var node_in_all_set : bool
#	var node_in_close : bool
#
#	if(node_position != current_node.position):
#		for node in all_set:
#			if(node.position == node_position):
#				node_in_all_set = true
#		for node_close in closed_set:
#			if(node_close.position == node_position):
#				node_in_close = true
#
#		if(node_in_all_set and not node_in_close):
#			for node in all_set:
#				if(node.is_equal(node_position)):
#					node.parent = current_node
##					node.H = manhattan_distance(node.position, end_node.position)
#					node.G = node.parent.G + get_diagonal(node.position, current_node.position)
#					node.F = node.G + node.H
#					open_set.append(node)





#### Metodo para calcular la distancia (manhattan) entre dos nodos
func manhattan_distance(point_1: Vector2, point_2: Vector2):
	return abs(point_1.x - point_2.x) + abs(point_1.y - point_2.y)


#### Como para la distancia de manhattan un nodo en diagonal esta a '2' de distancia
#### esto genera que distintos caminos tengan el mismo peso.
#### Por esto vamos a modificar un poco el valor devuelto para G
func get_diagonal(node_position: Vector2, parent_position: Vector2) -> int:
	var result: int = manhattan_distance(node_position, parent_position)
	
	## si el nodo evaluado esta en una fila y columna distinta al nodo padre
	## significa que esta en diagonal
	if node_position.x != parent_position.x and node_position.y != parent_position.y:
		result *= 7 # 2 * 7 = 14
	else:
		result *= 10 # 1 * 10 = 10
	
	return result


#### Metodo que itera en la lista de nodos abiertos y devuelve un nuevo nodo a cerrar/padre
func check_new_parent_node() -> PathNode:
	var F_min_node : PathNode
	var F_min : int = 9999
	for node in open_set:
		if(node.F < F_min):
			F_min = node.F
			F_min_node = node
	return F_min_node


#### Metodo que convierte a una posicion [x,y] en coordenadas [col, fila]
func pos_to_node(position: Vector2) -> Vector2:
	return world_to_map(position)


#### Metodo que convierte una coordenada [col, fila] a posiciones [x, y]
#### Como los centros de los tiles estan defasados 32 pixeles hay que sumar ese vector
func node_to_pos(node_coord: Vector2) -> Vector2:
	return map_to_world(node_coord) + Vector2(32.0, 32.0)





