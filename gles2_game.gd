extends Node2D

var city = {}
var pos = Vector2(44.1,288.6)
var heading = 0.4
var speed = 0.0
var zoom = 1.4
var roads = []
var buildings = []
var areas = []
var labels = []
var font
var elapsed = 0.0

func _ready():
    var f = File.new()
    if f.open("res://city.json", File.READ) == OK:
        var parsed = JSON.parse(f.get_as_text())
        if parsed.error == OK:
            city = parsed.result
        f.close()
    if city.has("start"):
        pos = Vector2(city["start"][0],city["start"][1])
    if city.has("sdir"):
        heading = atan2(city["sdir"][0],-city["sdir"][1])
    print("MAKKAH_DATA_LOADED roads=",city.get("roads",[]).size()," buildings=",city.get("bld",[]).size())
    roads = city.get("roads",[])
    buildings = city.get("bld",[])
    areas = city.get("areas",[])
    labels = city.get("poi",[])
    font = Control.new().get_font("font")
    set_process(true)

func _process(delta):
    elapsed += delta
    var steer = 0.0
    if Input.is_action_pressed("ui_left"): steer -= 1.0
    if Input.is_action_pressed("ui_right"): steer += 1.0
    if Input.is_action_pressed("ui_up"): speed = min(speed + 85.0 * delta, 160.0)
    elif Input.is_action_pressed("ui_down"): speed = max(speed - 130.0 * delta,-55.0)
    else: speed = move_toward(speed,0.0,50.0 * delta)
    heading += steer * delta * (0.5 + min(abs(speed) / 80.0,1.0)) * (1.0 if speed >= 0 else -1.0)
    pos += Vector2(sin(heading),-cos(heading)) * speed * delta
    if Input.is_action_just_pressed("ui_accept"): zoom = 2.2 if zoom < 2.0 else 1.4
    update()

func visible_point(p):
    return abs(p.x-pos.x)<750 and abs(p.y-pos.y)<500

func polygon_points(vertices):
    var out = PoolVector2Array()
    for p in vertices:
        out.append(Vector2(p[0],p[1]))
    return out

func _draw():
    var view = get_viewport_rect().size
    draw_rect(Rect2(Vector2.ZERO,view),Color("#c5bca3"))
    draw_set_transform(view * 0.5 - pos * zoom,0.0,Vector2(zoom,zoom))
    for a in areas:
        if not a.has("v"): continue
        var v = a["v"]
        if v.size()<3: continue
        var origin = Vector2(v[0][0],v[0][1])
        if not visible_point(origin): continue
        var col = Color("#d8d0b8")
        if a.get("k","")=="marble": col=Color("#eae5db")
        draw_colored_polygon(polygon_points(v),col)
    for b in buildings:
        var v = b.get("v",[])
        if v.size()<3: continue
        var origin = Vector2(v[0][0],v[0][1])
        if not visible_point(origin): continue
        draw_colored_polygon(polygon_points(v),Color("#a39883"))
    for road in roads:
        if road.size()<3: continue
        var v = road[2]
        if v.size()<2: continue
        var pts=polygon_points(v)
        var first=pts[0]
        if not visible_point(first): continue
        var w = float(road[0])
        draw_polyline(pts,Color("#eee9dd"),max(3.0,w),true)
        draw_polyline(pts,Color("#6f706e"),1.0,true)
    draw_circle(Vector2(0,0),24,Color("#e5e0d5"))
    draw_rect(Rect2(Vector2(-8,-8),Vector2(16,16)),Color("#28221d"))
    draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
    var center=view*0.5
    var fwd=Vector2(sin(heading),-cos(heading))
    var side=Vector2(-fwd.y,fwd.x)
    var car=PoolVector2Array([center+fwd*19,center-fwd*14+side*10,center-fwd*14-side*10])
    draw_colored_polygon(car,Color("#e63e29"))
    draw_circle(center,4,Color.white)
    draw_rect(Rect2(0,0,view.x,58),Color(0.06,0.11,0.15,0.85))
    draw_string(font,Vector2(18,26),"CITY FREEDOM  -  MAKKAH",Color.white)
    draw_string(font,Vector2(18,46),"MI BOX GLES2 | Real Makkah map | D-PAD DRIVE | OK ZOOM",Color("#c9e7fa"))
    if roads.empty():
        draw_rect(Rect2(10,80,view.x-20,85),Color(0.65,0.05,0.05,0.9))
        draw_string(font,Vector2(20,110),"ERROR: MAKKAH MAP DATA NOT LOADED",Color.white)
        draw_string(font,Vector2(20,138),"city.json missing from Android package",Color.white)
    draw_rect(Rect2(0,view.y-35,view.x,35),Color(0.06,0.11,0.15,0.85))
    draw_string(font,Vector2(18,view.y-13),"SPEED: "+str(int(abs(speed)))+" km/h     ROADS: "+str(roads.size())+"     BUILDINGS: "+str(buildings.size()),Color.white)
