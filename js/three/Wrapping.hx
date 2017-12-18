package js.three;

@:native("THREE")
@:enum
extern abstract Wrapping(Int)
{
	var RepeatWrapping;
	var ClampToEdgeWrapping;
	var MirroredRepeatWrapping;
}