package js.three;

import js.html.*;

@:native("THREE")
@:enum
extern abstract PixelFormat(Int)
{
	var AlphaFormat;
	var RGBFormat;
	var RGBAFormat;
	var LuminanceFormat;
	var LuminanceAlphaFormat;
	var RGBEFormat;
	var DepthFormat;
	var DepthStencilFormat;
}