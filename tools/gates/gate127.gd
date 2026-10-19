extends SceneTree

func _init() -> void :
	var fail: = 0
	var on: = 0
	for i in 1000:
		on += int(CrowdFX.flash_pulse(i * 0.01, 0.0, 1.0))
	print("fraccion encendido: ", on / 1000.0)
	if on < 80 or on > 140:
		print("FAIL: duty fuera de rango");fail += 1
	var crowd: CrowdFX = CrowdFX.new()
	root.add_child(crowd)
	crowd.build()
	await process_frame
	if crowd == null:
		print("FAIL: sin grada");fail += 1
	else:
		crowd.start_flashes(2.0)
		if crowd.flash_mm == null:
			print("FAIL: no crea flashes");fail += 1
		else:
			var lit: = 0
			for i in 130:
				crowd.update(1.0 / 60.0, 0.0)
				for k in CrowdFX.FLASH_SITES:
					if crowd.flash_mm.multimesh.get_instance_transform(k).basis.x.x > 0.01:
						lit += 1
						break
			print("frames con algun flash: ", lit, "/130")
			if lit < 10:
				print("FAIL: casi nunca destella");fail += 1
			for i in 60:
				crowd.update(1.0 / 60.0, 0.0)
			var still: = 0
			for k in CrowdFX.FLASH_SITES:
				if crowd.flash_mm.multimesh.get_instance_transform(k).basis.x.x > 0.01:
					still += 1
			if still != 0:
				print("FAIL: no se apaga");fail += 1
	print("gate127 ", "PASS" if fail == 0 else "FAIL")
	quit(1 if fail > 0 else 0)
