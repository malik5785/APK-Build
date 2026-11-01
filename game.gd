extends Spatial
# V11 real-map data based Godot 3.6 GLES2 compatibility implementation.
# This is NOT a complete line-by-line port of original_v11_reference/main.gd.
var city = {}
var pos = Vector3(44,0,289)
var heading = 0.0
var velocity = 0.0
var driving = true
var car
var walker
var camera
var hud
var sun
var routes = []
var traffic = []
var time_of_day = 10.0
var materials = {}
var camera_mode = 0
var pedestrians = []
var city_audio = null
var horn_audio = null
var outfit_index = 0
var outfit_colors = ["#e9e7df", "#3b4659", "#9b8d7d", "#ffffff"]
var player_body = null

func mat(color):
    if materials.has(color): return materials[color]
    var m = SpatialMaterial.new()
    m.albedo_color = Color(color)
    materials[color] = m
    return m

func box(parent, where, size, color):
    var n = MeshInstance.new()
    var mesh = CubeMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = mat(color)
    parent.add_child(n)
    n.translation = where
    return n

func vehicle(parent, color):
    box(parent,Vector3(0,0.6,0),Vector3(2,0.7,4),color)
    box(parent,Vector3(0,1.15,-0.25),Vector3(1.7,0.7,2),"#273c4a")
    for side in [-1,1]:
        for z in [-1.35,1.35]:
            box(parent,Vector3(side*1.05,0.33,z),Vector3(0.24,0.65,0.65),"#171717")
        box(parent,Vector3(side*0.7,0.65,-2.02),Vector3(0.35,0.16,0.05),"#fff3cf")
        box(parent,Vector3(side*0.7,0.65,2.02),Vector3(0.35,0.16,0.05),"#c82929")

func _ready():
    var f = File.new()
    if f.open("res://data/city.json",File.READ)==OK:
        var parsed = JSON.parse(f.get_as_text())
        if parsed.error==OK: city=parsed.result
        f.close()
    var start = city.get("start",[44,289])
    pos = Vector3(float(start[0]),0,float(start[1]))
    var world = WorldEnvironment.new()
    world.environment = Environment.new()
    world.environment.background_mode = Environment.BG_COLOR
    world.environment.background_color = Color("#89b5d2")
    add_child(world)
    sun = DirectionalLight.new()
    sun.rotation_degrees = Vector3(-55,35,0)
    add_child(sun)
    box(self,Vector3(0,-1,0),Vector3(8500,2,8500),"#cdbf9e")
    var origin = Vector2(pos.x,pos.z)
    for road in city.get("roads",[]):
        if road.size()<3: continue
        var pts=road[2]
        var route=[]
        for pt in pts:
            if Vector2(float(pt[0]),float(pt[1])).distance_to(origin)<430:
                route.append(Vector3(float(pt[0]),0,float(pt[1])))
        if route.size()>3 and routes.size()<120: routes.append(route)
        for i in range(pts.size()-1):
            var a=Vector2(float(pts[i][0]),float(pts[i][1]))
            var b=Vector2(float(pts[i+1][0]),float(pts[i+1][1]))
            var middle=(a+b)*0.5
            if middle.distance_to(origin)>360: continue
            var delta=b-a
            if delta.length()<0.2: continue
            var road_mesh=box(self,Vector3(middle.x,0.03,middle.y),Vector3(max(3.0,float(road[0])),0.06,delta.length()),"#555b5e")
            road_mesh.rotation.y=-atan2(delta.x,delta.y)
    # Actual footprint edges and roof triangles, rather than bounding-box towers.
    var walls=SurfaceTool.new()
    walls.begin(Mesh.PRIMITIVE_TRIANGLES)
    var roofs=SurfaceTool.new()
    roofs.begin(Mesh.PRIMITIVE_TRIANGLES)
    var count=0
    for building in city.get("bld",[]):
        var pts=building.get("v",[])
        if pts.size()<3: continue
        var center=Vector2()
        for pt in pts: center+=Vector2(float(pt[0]),float(pt[1]))
        center/=float(pts.size())
        if center.distance_to(origin)>380: continue
        var h=clamp(float(building.get("h",15)),3.0,90.0)
        var color_code=str(building.get("c","b9ac98"))
        if not color_code.begins_with("#"): color_code="#"+color_code
        var color=Color(color_code)
        for i in range(pts.size()):
            var j=(i+1)%pts.size()
            var p=Vector3(float(pts[i][0]),0,float(pts[i][1]))
            var q=Vector3(float(pts[j][0]),0,float(pts[j][1]))
            if p.distance_to(q)<0.05: continue
            for v in [p,q,q+Vector3(0,h,0),p,q+Vector3(0,h,0),p+Vector3(0,h,0)]:
                walls.add_color(color)
                walls.add_vertex(v)
        var tris=building.get("t",[])
        for i in range(0,tris.size()-2,3):
            var a=int(tris[i]); var b=int(tris[i+1]); var d=int(tris[i+2])
            if a<0 or b<0 or d<0 or a>=pts.size() or b>=pts.size() or d>=pts.size(): continue
            for ix in [a,b,d]:
                roofs.add_color(color.lightened(0.12))
                roofs.add_vertex(Vector3(float(pts[ix][0]),h,float(pts[ix][1])))
        count+=1
    if count>0:
        var surface_mat=SpatialMaterial.new()
        surface_mat.vertex_color_use_as_albedo=true
        surface_mat.params_cull_mode=SpatialMaterial.CULL_DISABLED
        var wall_node=MeshInstance.new()
        wall_node.mesh=walls.commit()
        wall_node.material_override=surface_mat
        add_child(wall_node)
        var roof_node=MeshInstance.new()
        roof_node.mesh=roofs.commit()
        roof_node.material_override=surface_mat
        add_child(roof_node)
    var tree_count=0
    for pt in city.get("trees",[]):
        if tree_count>=140: break
        var p=Vector2(float(pt[0]),float(pt[1]))
        if p.distance_to(origin)>300: continue
        box(self,Vector3(p.x,2,p.y),Vector3(0.4,4,0.4),"#785c3d")
        box(self,Vector3(p.x,5,p.y),Vector3(3,2.8,3),"#4b794d")
        tree_count+=1
    var kaaba=city.get("kaaba",[])
    if kaaba.size()>=2:
        var k=Vector3(float(kaaba[0]),0,float(kaaba[1]))
        box(self,k+Vector3(0,7,0),Vector3(13,14,12),"#211d1c")
        box(self,k+Vector3(0,10,0),Vector3(13.2,1.2,12.2),"#c6a35c")
    var tower=city.get("clock",[])
    if tower.size()>=2:
        var t=Vector2(float(tower[0]),float(tower[1]))
        if t.distance_to(origin)<900:
            box(self,Vector3(t.x,60,t.y),Vector3(36,120,34),"#b5a992")
            box(self,Vector3(t.x,137,t.y),Vector3(24,34,24),"#d4c8aa")
    car=Spatial.new()
    add_child(car)
    vehicle(car,"#d62f30")
    walker=Spatial.new()
    add_child(walker)
    player_body=box(walker,Vector3(0,1.1,0),Vector3(0.65,1.3,0.45),"#e9e7df")
    box(walker,Vector3(0,1.92,0),Vector3(0.43,0.43,0.43),"#a87b60")
    for i in range(10):
        if routes.empty(): break
        var n=Spatial.new()
        add_child(n)
        vehicle(n,"#c5c5c2" if i%2==0 else "#445e79")
        traffic.append({"node":n,"route":routes[(i*7)%routes.size()],"seg":0,"fraction":float(i%4)*0.2,"speed":7.0+float(i%3)*2.0})
    for i in range(24):
        var ped=Spatial.new()
        add_child(ped)
        box(ped,Vector3(0,0.95,0),Vector3(0.45,1.4,0.35),"#e9e6dc" if i%3==0 else "#766b63")
        box(ped,Vector3(0,1.85,0),Vector3(0.38,0.38,0.38),"#b28b6c")
        var ang=float(i)*2.39996
        var rad=25.0+float(i%9)*18.0
        pedestrians.append({"node":ped,"origin":pos+Vector3(cos(ang)*rad,0,sin(ang)*rad),"phase":float(i)*0.6})
    city_audio=AudioStreamPlayer.new()
    add_child(city_audio)
    city_audio.stream=load("res://audio/city.wav")
    if city_audio.stream!=null: city_audio.play()
    horn_audio=AudioStreamPlayer.new()
    add_child(horn_audio)
    horn_audio.stream=load("res://audio/horn.wav")
    camera=Camera.new()
    camera.current=true
    camera.far=1600
    add_child(camera)
    var layer=CanvasLayer.new()
    add_child(layer)
    hud=Label.new()
    hud.rect_position=Vector2(20,20)
    layer.add_child(hud)

func _unhandled_input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.scancode==KEY_H and horn_audio!=null and horn_audio.stream!=null: horn_audio.play()
        if event.scancode==KEY_W and player_body!=null:
            outfit_index=(outfit_index+1)%outfit_colors.size()
            player_body.material_override=mat(outfit_colors[outfit_index])

func _process(dt):
    var steer=int(Input.is_action_pressed("ui_right"))-int(Input.is_action_pressed("ui_left"))
    if Input.is_action_pressed("ui_up"): velocity=min(velocity+18.0*dt,30.0 if driving else 6.0)
    elif Input.is_action_pressed("ui_down"): velocity=max(velocity-22.0*dt,-12.0 if driving else -4.0)
    else: velocity=lerp(velocity,0.0,min(1.0,dt*2.0))
    if Input.is_action_just_pressed("ui_accept"):
        driving=not driving
        velocity=0
    if Input.is_action_just_pressed("ui_cancel"): camera_mode=(camera_mode+1)%3
    heading+=steer*dt*(1.1 if driving else 2.2)
    pos+=Vector3(sin(heading),0,-cos(heading))*velocity*dt
    car.visible=driving
    walker.visible=not driving
    car.translation=pos
    car.rotation.y=heading
    walker.translation=pos
    walker.rotation.y=heading
    for item in traffic:
        var route=item["route"]
        var seg=int(item["seg"])
        if route.size()<2: continue
        var a=route[seg]
        var b=route[seg+1]
        item["fraction"]+=dt*float(item["speed"])/max(0.1,a.distance_to(b))
        if item["fraction"]>=1.0:
            item["fraction"]=0.0
            item["seg"]=(seg+1)%(route.size()-1)
            seg=int(item["seg"])
            a=route[seg]
            b=route[seg+1]
        item["node"].translation=a.linear_interpolate(b,float(item["fraction"]))
        item["node"].rotation.y=atan2(b.x-a.x,b.z-a.z)
    for ped in pedestrians:
        ped["phase"]+=dt*0.42
        ped["node"].translation=ped["origin"]+Vector3(cos(ped["phase"])*4.0,0,sin(ped["phase"])*4.0)
        ped["node"].rotation.y=-ped["phase"]
    time_of_day=fmod(time_of_day+dt*0.01,24.0)
    sun.rotation_degrees.x=-65.0*sin(time_of_day*PI/12.0)
    sun.light_energy=0.85 if time_of_day>6.0 and time_of_day<18.0 else 0.16
    var distance=13.0 if camera_mode==0 else (6.0 if camera_mode==1 else 0.2)
    var height=8.0 if camera_mode==0 else (4.0 if camera_mode==1 else 2.5)
    camera.translation=pos+Vector3(-sin(heading)*distance,height,cos(heading)*distance)
    camera.look_at(pos+Vector3(0,1,0),Vector3.UP)
    hud.text="CITY FREEDOM MAKKAH | V11 REALMAP GLES2 COMPATIBILITY\nD-PAD MOVE | OK WALK/DRIVE | BACK CAMERA\n"+str(int(abs(velocity)*3.6))+" km/h | "+str(int(time_of_day))+":00"
