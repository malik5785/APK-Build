extends Spatial

var city = {}
var roads = []
var buildings = []
var player_pos = Vector3(44,1,289)
var heading = 0.0
var speed = 0.0
var car
var camera
var hud
var material_cache = {}
var driving = true
var walker
var traffic = []
var clock = 0.0

func material(c):
    if material_cache.has(c): return material_cache[c]
    var m = SpatialMaterial.new()
    m.albedo_color = Color(c)
    material_cache[c] = m
    return m

func block(parent, at, size, color):
    var obj = MeshInstance.new()
    var mesh = CubeMesh.new()
    mesh.size = size
    obj.mesh = mesh
    obj.material_override = material(color)
    parent.add_child(obj)
    obj.translation = at
    return obj

func _ready():
    var file = File.new()
    if file.open("res://city.json",File.READ) == OK:
        var parsed = JSON.parse(file.get_as_text())
        if parsed.error == OK: city = parsed.result
        file.close()
    roads = city.get("roads",[])
    buildings = city.get("bld",[])
    if city.has("start"):
        player_pos = Vector3(city["start"][0],1,city["start"][1])
    var world = WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("#8ab9d4")
    add_child(world)
    var sun = DirectionalLight.new()
    sun.rotation_degrees = Vector3(-55,35,0)
    add_child(sun)
    block(self,Vector3(0,-1,0),Vector3(8500,2,8500),"#c8b99b")
    var origin = Vector2(player_pos.x,player_pos.z)
    for road in roads:
        if road.size()<3: continue
        var pts = road[2]
        for i in range(pts.size()-1):
            var a = Vector2(pts[i][0],pts[i][1])
            var b = Vector2(pts[i+1][0],pts[i+1][1])
            var mid = (a+b)*0.5
            if mid.distance_to(origin)>380: continue
            var d = b-a
            if d.length()<0.5: continue
            var obj = block(self,Vector3(mid.x,0.04,mid.y),Vector3(max(3,float(road[0])),0.08,d.length()),"#56595b")
            obj.rotation.y = -atan2(d.x,d.y)
    for building in buildings:
        var pts = building.get("v",[])
        if pts.size()<3: continue
        var low = Vector2(100000,100000)
        var high = Vector2(-100000,-100000)
        for pt in pts:
            var p = Vector2(pt[0],pt[1])
            low.x = min(low.x,p.x)
            low.y = min(low.y,p.y)
            high.x = max(high.x,p.x)
            high.y = max(high.y,p.y)
        var mid = (low+high)*0.5
        if mid.distance_to(origin)>380: continue
        var h = clamp(float(building.get("h",15)),5,65)
        block(self,Vector3(mid.x,h*0.5,mid.y),Vector3(max(2,high.x-low.x),h,max(2,high.y-low.y)),"#b6aa96")
    block(self,Vector3(0,11,0),Vector3(16,22,16),"#282421")
    car = Spatial.new()
    add_child(car)
    block(car,Vector3(0,0.6,0),Vector3(2.2,0.8,4.2),"#d9322c")
    block(car,Vector3(0,1.2,0),Vector3(1.8,0.65,2.2),"#263b49")
    walker = Spatial.new()
    add_child(walker)
    block(walker,Vector3(0,1,0),Vector3(0.65,1.25,0.4),"#f0f0e9")
    block(walker,Vector3(0,1.85,0),Vector3(0.4,0.42,0.42),"#ae826a")
    for i in range(12):
        var npc = Spatial.new()
        add_child(npc)
        block(npc,Vector3(0,0.6,0),Vector3(2,0.7,3.8),"#3d526b" if i%3==0 else "#ddddda")
        block(npc,Vector3(0,1.15,0),Vector3(1.6,0.6,1.8),"#283843")
        traffic.append({"node":npc,"angle":float(i)*0.52,"radius":85.0+float(i%4)*38.0,"speed":0.05+float(i%3)*0.015})
    camera = Camera.new()
    camera.current = true
    camera.far = 1800
    add_child(camera)
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.rect_position = Vector2(20,20)
    layer.add_child(hud)

func _process(dt):
    var steer = int(Input.is_action_pressed("ui_right"))-int(Input.is_action_pressed("ui_left"))
    if Input.is_action_pressed("ui_up"): speed = min(speed+18*dt,30)
    elif Input.is_action_pressed("ui_down"): speed = max(speed-22*dt,-12)
    else: speed = lerp(speed,0.0,min(1,dt*2))
    if Input.is_action_just_pressed("ui_accept"):
        driving = not driving
        speed = 0
    heading += steer*dt*(1.1 if driving else 2.2)
    player_pos += Vector3(sin(heading),0,-cos(heading))*speed*dt
    if not driving:
        speed = clamp(speed,-4,6)
    car.visible = driving
    walker.visible = not driving
    walker.translation = player_pos
    walker.rotation.y = heading
    clock += dt
    for t in traffic:
        var a = t["angle"]+clock*t["speed"]
        var n = t["node"]
        n.translation = Vector3(44.1+cos(a)*t["radius"],1,288.6+sin(a)*t["radius"])
        n.rotation.y = -a
    car.translation = player_pos
    car.rotation.y = heading
    camera.translation = player_pos + Vector3(-sin(heading)*13,8,cos(heading)*13)
    camera.look_at(player_pos,Vector3.UP)
    hud.text = "CITY FREEDOM MAKKAH | 3D GLES2 PORT\nD-PAD MOVE | OK WALK/DRIVE | "+str(int(abs(speed)*3.6))+" km/h\nOSM roads "+str(roads.size())+" | buildings "+str(buildings.size())
