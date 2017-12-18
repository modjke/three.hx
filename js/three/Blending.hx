package js.three;

import js.html.*;

@:native("THREE")
@:enum
extern abstract Blending(Int) {
	var NoBlending; 
	var NormalBlending;
	var AdditiveBlending;
	var SubtractiveBlending;
	var MultiplyBlending; 
	var CustomBlending;
}