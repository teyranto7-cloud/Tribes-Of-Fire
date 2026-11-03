extends Node3D
const Shapes = preload("res://World/Shapes.gd")
const Balance = preload("res://Game/Balance.gd")
var fish_id: int
var center := Vector3.ZERO
var age: float = 0.0
var stock: int = 8
var restock_at: float = 0.0
var tail: Node3D
func setup(id: int, at: Vector3) -> void:
	fish_id=id;center=at;position=at;age=id*1.7
	Shapes.sculpted(self,Vector3.ZERO,Vector3(0.15,0.17,0.52),Color("#899fa0"),"body",id)
	tail=Node3D.new();tail.position.z=0.27;add_child(tail)
	var fin=Shapes.sculpted(tail,Vector3(0,0,0.1),Vector3(0.20,0.18,0.035),Color("#5c7d81"),"leaf",id)
	fin.rotation.x=PI*0.5
	for side in [-1,1]: Shapes.sculpted(self,Vector3(side*0.06,0.035,-0.17),Vector3.ONE*0.035,Color("#202e2c"),"head",id)
func _process(delta: float) -> void:
	var game = get_parent().get_parent()
	if "clock" in game: age=lerpf(age,float(game.clock.elapsed)+fish_id*1.7,minf(1,delta*6))
	else: age+=delta
	position=center+Vector3(sin(age*0.55)*1.7,sin(age*0.9)*0.08,cos(age*0.55)*1.7)
	rotation.y=-age*0.55
	if tail!=null: tail.rotation.y=sin(age*7)*0.35
	visible=stock>0
func advance() -> void:
	if stock==0 and Time.get_unix_time_from_system()>=restock_at:
		stock=Balance.integer("fishing","maximum_stock",8);restock_at=0
func take() -> bool:
	if stock<=0: return false
	stock-=1
	if stock==0: restock_at=Time.get_unix_time_from_system()+Balance.number("fishing","restock_seconds",300)
	return true
func state() -> Dictionary:
	return {"id":fish_id,"stock":stock,"restock_at":restock_at}
func restore(data: Dictionary) -> void:
	stock=int(data["stock"]);restock_at=float(data["restock_at"]);visible=stock>0
