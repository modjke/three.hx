package js.three;

@:native("THREE")
@:enum
extern abstract Mapping(Int)
{
	var UVMapping;
	var CubeReflectionMapping;
	var CubeRefractionMapping;
	var EquirectangularReflectionMapping;
	var EquirectangularRefractionMapping;
	var SphericalReflectionMapping;
	var CubeUVReflectionMapping;
	var CubeUVRefractionMapping;
}