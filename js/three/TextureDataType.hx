package js.three;

import js.html.*;

@:native("THREE")
@:enum
extern abstract TextureDataType(Int)
{
	var UnsignedByteType;
	var ByteType;
	var ShortType;
	var UnsignedShortType;
	var IntType;
	var UnsignedIntType;
	var FloatType;
	var HalfFloatType;
}