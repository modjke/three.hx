package js.three;

@:native("THREE")
@:enum
extern abstract TextureFilter(Int)
{
	var NearestFilter;
	var NearestMipMapNearestFilter;
	var NearestMipMapLinearFilter;
	var LinearFilter;
	var LinearMipMapNearestFilter;
	var LinearMipMapLinearFilter;
}