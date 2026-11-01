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
var road_routes = []
var pedestrians = []
var time_of_day = 10.0
var sun_node
var camera_mode = 0
var map_layer
var map_panel
var map_visible = false
var wardrobe_visible = false
var outfit_index = 0
var outfits = ["#f0f0e9","#293b58","#8b7355","#393939"]
var player_torso
var minimap
var title_label

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
    sun_node = sun
    block(self,Vector3(0,-1,0),Vector3(8500,2,8500),"#c8b99b")
    var origin = Vector2(player_pos.x,player_pos.z)
    for road in roads:
        if road.size()>2 and road[2].size()>3 and road_routes.size()<180:
            var route = []
            for point in road[2]:
                if Vector2(point[0],point[1]).distance_to(origin)<450:
                    route.append(Vector3(point[0],1,point[1]))
            if route.size()>3: road_routes.append(route)
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
    var kaaba_point = city.get("kaaba",[0,0])
    var kp = Vector3(kaaba_point[0],0,kaaba_point[1])
    block(self,kp+Vector3(0,7,0),Vector3(13,14,12),"#24201c")
    block(self,kp+Vector3(0,10,0),Vector3(13.2,1.2,12.2),"#c5a354")
    car = Spatial.new()
    add_child(car)
    block(car,Vector3(0,0.6,0),Vector3(2.2,0.8,4.2),"#d9322c")
    block(car,Vector3(0,1.2,0),Vector3(1.8,0.65,2.2),"#263b49")
    walker = Spatial.new()
    add_child(walker)
    player_torso = block(walker,Vector3(0,1,0),Vector3(0.65,1.25,0.4),"#f0f0e9")
    block(walker,Vector3(0,1.85,0),Vector3(0.4,0.42,0.42),"#ae826a")
    for i in range(12):
        var npc = Spatial.new()
        add_child(npc)
        block(npc,Vector3(0,0.6,0),Vector3(2,0.7,3.8),"#3d526b" if i%3==0 else "#ddddda")
        block(npc,Vector3(0,1.15,0),Vector3(1.6,0.6,1.8),"#283843")
        if road_routes.size()>0:
            traffic.append({"node":npc,"route":road_routes[(i*7)%road_routes.size()],"segment":0,"progress":float(i%5)*0.1,"speed":7.0+float(i%4)*2.0})
    for i in range(20):
        var person = Spatial.new()
        add_child(person)
        block(person,Vector3(0,1.05,0),Vector3(0.5,1.0,0.35),"#e9e5dc" if i%2==0 else "#42444b")
        block(person,Vector3(0,1.8,0),Vector3(0.35,0.38,0.35),"#a98166")
        pedestrians.append({"node":person,"angle":float(i)*0.314,"radius":25.0+float(i%5)*8.0})
    camera = Camera.new()
    camera.current = true
    camera.far = 1800
    add_child(camera)
    var layer = CanvasLayer.new()
    add_child(layer)
    hud = Label.new()
    hud.rect_position = Vector2(20,20)
    layer.add_child(hud)
    title_label = Label.new()
    title_label.text = "CITY FREEDOM | MAKKAH V10 GLES2 DEVELOPMENT"
    title_label.rect_position = Vector2(20,95)
    layer.add_child(title_label)
    map_panel = Control.new()
    map_panel.rect_position = Vector2(20,125)
    map_panel.rect_min_size = Vector2(220,220)
    layer.add_child(map_panel)
    minimap = Label.new()
    minimap.rect_position = Vector2(0,0)
    map_panel.add_child(minimap)
    map_panel.visible = false

func _process(dt):
    var steer = int(Input.is_action_pressed("ui_right"))-int(Input.is_action_pressed("ui_left"))
    if Input.is_action_pressed("ui_up"): speed = min(speed+18*dt,30)
    elif Input.is_action_pressed("ui_down"): speed = max(speed-22*dt,-12)
    else: speed = lerp(speed,0.0,min(1,dt*2))
    if Input.is_key_pressed(KEY_M) and not map_visible:
        map_visible = true
        map_panel.visible = true
    elif Input.is_key_pressed(KEY_N) and map_visible:
        map_visible = false
        map_panel.visible = false
    if Input.is_key_pressed(KEY_1):
        outfit_index = 0
    elif Input.is_key_pressed(KEY_2):
        outfit_index = 1
    elif Input.is_key_pressed(KEY_3):
        outfit_index = 2
    elif Input.is_key_pressed(KEY_4):
        outfit_index = 3
    player_torso.material_override = material(outfits[outfit_index])
    if Input.is_action_just_pressed("ui_cancel"):
        camera_mode = (camera_mode+1)%3
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
        var route = t["route"]
        var segment = int(t["segment"])
        if route.size()<2: continue
        var a = route[segment]
        var b = route[segment+1]
        t["progress"] += dt*t["speed"]/max(0.1,a.distance_to(b))
        if t["progress"]>=1.0:
            t["progress"] = 0.0
            t["segment"] = (segment+1)%(route.size()-1)
            segment = int(t["segment"])
            a = route[segment]
            b = route[segment+1]
        var n = t["node"]
        n.translation = a.linear_interpolate(b,t["progress"])
        n.rotation.y = atan2(b.x-a.x,b.z-a.z)
    for p in pedestrians:
        var a = p["angle"]+clock*0.06
        p["node"].translation = Vector3(44.1+cos(a)*p["radius"],0,288.6+sin(a)*p["radius"])
        p["node"].rotation.y = -a
    time_of_day = fmod(time_of_day+dt*0.015,24.0)
    sun_node.rotation_degrees.x = -65.0*sin(time_of_day*PI/12.0)
    sun_node.light_energy = 0.85 if time_of_day>6.0 and time_of_day<18.0 else 0.15
    car.translation = player_pos
    car.rotation.y = heading
    var distance = 13.0 if camera_mode==0 else (6.0 if camera_mode==1 else 0.1)
    var elevation = 8.0 if camera_mode==0 else (4.0 if camera_mode==1 else 2.5)
    camera.translation = player_pos + Vector3(-sin(heading)*distance,elevation,cos(heading)*distance)
    camera.look_at(player_pos,Vector3.UP)
    minimap.text = "MAP / DISTRICT\nX: "+str(int(player_pos.x))+" Z: "+str(int(player_pos.z))+"\nROADS: "+str(roads.size())+"\nM close: N\nOUTFITS: 1-4"
    hud.text = "CITY FREEDOM MAKKAH | 3D GLES2 PORT\nD-PAD MOVE | OK WALK/DRIVE | BACK CAMERA | "+str(int(abs(speed)*3.6))+" km/h\nOSM roads "+str(roads.size())+" | buildings "+str(buildings.size())
