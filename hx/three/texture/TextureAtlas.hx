package hx.three.texture;
import haxe.ds.StringMap;
import js.three.Texture;


typedef TextureFrame = {>AtlasFrame,
	texture:Texture
}

typedef AtlasFrame = { x:Float, y:Float, w:Float, h:Float}

typedef AtlasJson = {
	frames:Dynamic<{ frame:AtlasFrame }>
}



class TextureAtlas
{
	public static function getMetaImage(data:{ meta: { image: String }}):String {
		try {
			return data.meta.image;
		} catch (ignore:Dynamic) {}
		return null;
	}
	
	var frames = new StringMap<TextureFrame>();
	var atlasTexture:Texture;

	public function getFrame(name:String):TextureFrame
	{
		if (!frames.exists(name)) throw "Can't find a frame with a name " + name;
		
		
		var frame = frames.get(name);
		if (frame.texture == null)
		{
			frame.texture = atlasTexture.clone();
			applyFrame(frame.texture, frame);
		}
		
		return frame;
	}
	
	public function new(json:AtlasJson, texture:Texture) 
	{		
		
		this.atlasTexture = texture;
		
		var filenames = Reflect.fields(json.frames);
		for (filename in filenames) {
			var f:AtlasFrame = untyped Reflect.field(json.frames, filename).frame;

			frames.set(filename, {
				texture: null,
				w: f.w,
				h: f.h,
				x: f.x,
				y: f.y
			});
		}
	}
	
	static function applyFrame(texture:Texture, frame:AtlasFrame)
	{
		var w:Int = untyped texture.image.width;
		var h:Int = untyped texture.image.height;
		
		texture.flipY = true;
		texture.offset.x = frame.x / w;
		texture.offset.y = 1.0 - (frame.y + frame.h) / h;
		texture.repeat.x = frame.w / w;	
		texture.repeat.y = frame.h / h;        
		texture.needsUpdate = true;
	}
	
}