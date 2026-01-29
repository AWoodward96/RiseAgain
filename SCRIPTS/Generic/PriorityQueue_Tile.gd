extends Object
class_name PriorityQueue_Tile

var data : Array[TileQueue]
var size : int :
	get:
		return data.size()

func Enqueue(_entry : TileQueue):
	data.append(_entry)

	var index = size - 1
	while index > 0:
		var parent = (index - 1) / 2

		if data[index].weight >= data[parent].weight:
			break

		Swap(index, parent)

func Dequeue():
	var returnData = data[0]
	data[0] = data[size - 1]
	data.remove_at(size - 1)

	var index = 0
	while (true): # Uh oh here we go
		var childIndex = index * 2 + 1
		if childIndex > size - 1:
			break

		var rightIndex = childIndex + 1
		if rightIndex <= size - 1 && data[rightIndex].weight < data[childIndex].weight:
			childIndex = rightIndex

		if data[index].weight <= data[childIndex].weight:
			break

		Swap(index, childIndex)
		index = childIndex
	return returnData


func Swap(_index1 : int, _index2 : int):
	var tempData = data[_index1]
	data[_index1] = data[_index2]
	data[_index2] = tempData
