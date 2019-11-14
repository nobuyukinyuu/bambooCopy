extends Panel
enum OP {AR, DR, SR, RR, SL, TL, KS, ML, DT, DT2, AMS_ENABLE}

#Params: AR DR SR RR SL TL KS MUL DT1 DT2(unused) AMS-EN(unused)
#	(See notes for more details)
var params = []

func _ready():
	set_line_to_zero()

func setOP(paramString:String = ""):
	if paramString == "":
		set_line_to_zero()
		return

	params = paramString.split_floats(" ", false)
	set_line()

#Sets the line based on the current params.
func set_line():
	if params.size() == 0:
		print ("NO PARAMETERS SET FOR %s", get_parent().name)
		return
		
	var height = rect_size.y

	set_line_to_full()
	var ar = params[OP.AR]  #Attack rate x offset
	var dr = params[OP.DR]  #Decay rate x offset
	var sr = params[OP.SR]  #Sustain rate x offset
	var rr = params[OP.RR]  #Release rate x offset
	var sl = height * (params[OP.SL] / 15)  #Computed Y value for sustain level, 0-100%
	
	#Set attack
	if ar == 0:  #Attack rate 0 mutes everything in this chip
		set_line_to_zero()
		return
	else:
		$Line.points[1].x = 31 - ar
		
	#Set Decay
	if dr == 0:  #Decay rate 0 means we can ignore SR and SL.
		for i in range(2, 4):
			$Line.points[i] = $Line.points[1]
	else:
		#Decay line points are from AR's X position + 0 to 31 based on DR
		$Line.points[2].x = (31-dr) + (31 - ar)
		
		#Set the sustain level Y.
		$Line.points[2].y = sl 
		$Line.points[3].y = sl 
		$Line.points[4].y = sl 

		#Set SR's x value.  206 is just a default if the sustain rate is infinity.
		var percent = (31-sr) / 31
		$Line.points[3].x = lerp($Line.points[2].x, 206, percent)
	
		#Set release rate X and Y.  If RR is 0 then no key-off at all.
		if rr == 0:
			$Line.points[5].x = 294  #Replace with width?
			$Line.points[5].y = sl
		else:
			$Line.points[5].y = height
			
			var rr_percent = (15-rr) / 15
			$Line.points[4].x = lerp($Line.points[3].x , $Line.points[5].x, rr_percent)
			$Line.points[5].x = $Line.points[4].x
	
	#Set total level.
	var tl_percent = params[OP.TL] / 127
#	print("lerping TL percent for %s: " % get_parent().name, tl_percent)
	for i in $Line.points.size():
		$Line.points[i].y = lerp($Line.points[i].y, height, tl_percent)


	update()
	
func _draw():
	var height = rect_size.y
	for pt in $Line.points:
		draw_line(Vector2(pt.x, 0), Vector2(pt.x, height), ColorN("white", 0.2), 1, true)
	

func set_line_to_full():
	for i in $Line.points.size():
		$Line.points[i].y = 0

	$Line.points[0].y = rect_size.y
	$Line.points[5].x = 294  #Replace with width?
	$Line.points[5].y = rect_size.y

func set_line_to_zero():
	var height = rect_size.y
	for i in $Line.points.size():
		$Line.points[i].y = height
		
