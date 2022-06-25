extends PuzzlePanel

func mouse_to_local(pos : Vector3) -> Vector3:
#	print(pos)
	var trans := global_transform.affine_inverse()
	var ans := trans * pos
#	print(ans)
	ans.y *= -1
	var scaled := Vector3(0.5,(ans.y+2.8)/(5.6),0)
	var ang := -Vector2(ans.x, ans.z).rotated(-PI/2).angle()
	scaled.x = ang/TAU + 0.5
	scaled.x *= viewport_size.x
	scaled.y *= viewport_size.y
	return scaled

func mouse_to_global(pos : Vector3) -> Vector3:
#	print(">> ", pos)
	var trans := global_transform
	var scaled := pos
	scaled.x /= viewport_size.x
	scaled.x  = -(scaled.x - 0.5) * TAU
	var ang := Vector2.from_angle(scaled.x).rotated(PI/2)
	scaled.x = ang.x
	scaled.z = ang.y
	scaled.y /= viewport_size.y
	scaled.y = scaled.y*5.6-2.8
	scaled.y *= -1
	var ans := trans * scaled
	return ans
