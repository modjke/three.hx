package hx.three.loader;
import hx.three.loader.englercj.Loader;
import hx.three.loader.englercj.Resource;
import hx.three.texture.TextureAtlas;
import js.Browser;
import js.Three;
import js.three.Texture;


class ThreeLoader 
{
	var loader:Loader;
	var pending:Array<String> = [];
	var pendingCallbacks:Array<Void->Void> = [];
	
	public function new() 
	{
		loader = new Loader();
		loader.onComplete.add(_onComplete);
		loader.pre(_preMiddleware);
		loader.use(_useMiddleware);
	}
	
	function _onComplete()
	{
		if (pending.length == 0) {
			var callbacks = pendingCallbacks.splice(0, pendingCallbacks.length);
			for (cb in callbacks) cb();
		} else
			load();
	}
	
	public function add(url:String)
	{
		pending.push(url);
	}
	
	public function addList(urls:Array<String>)
	{
		for (url in urls) pending.push(url);
	}
	
	public function loadTexture(url:String, cb:Texture->Void)
	{
		add(url);
		load(function ()
		{
			cb(getTexture(url));
		});
	}
	
	public function load(?cb:Void->Void)
	{	
		if (pending.length == 0)
			throw "Nothing to load";
			
		if (cb != null)
			pendingCallbacks.push(cb);
		
		if (!loader.loading)
		{
			var urls = pending.splice(0, pending.length);		
			for (url in urls) loader.add(url);
			loader.load();
		}
	}
	
	public function getTexture(url:String):Texture
	{
		return getResource(url).texture;
	}
	
	public function getAtlas(url:String):TextureAtlas
	{
		return getResource(url).atlas;
	}
	
	function getResource(url:String):ThreeResource
	{
		var res = loader.resources.get(url);
		if (res == null) throw 'Resource $url not found';
		return res;
	}
	
	function _preMiddleware(resource:ThreeResource, next:Void->Void):Void	
	{
		next();
	}
	
	
	function _useMiddleware(resource:ThreeResource, next:Void->Void)
	{		
		switch (resource.type)
		{
			case IMAGE:				
				resource.texture = new Texture(resource.data);				
				resource.texture.format = ~/(jpeg|jpg)/i.match(resource.extension) ? Three.RGBFormat : Three.RGBAFormat;
				resource.texture.needsUpdate = true;
				
				Browser.window.requestAnimationFrame(cast next);
			case JSON:
	
				var atlasImage = TextureAtlas.getMetaImage(resource.data);
				if (atlasImage != null)
				{
					var atlasImageUrl = resource.url.substring(0, resource.url.lastIndexOf('/') + 1) + atlasImage;
					loader.add(atlasImageUrl, {
						crossOrigin: resource.crossOrigin,
						loadType: LoadType.IMAGE,
						parentResource: resource
					}, function (atlas:ThreeResource)
					{
						resource.atlas = new TextureAtlas(resource.data, atlas.texture);
						Browser.window.requestAnimationFrame(cast next);
					});
				} else 
					next();
					
			case _:				
				next();
		}
		
		
	}
}

@:forward
abstract ThreeResource(Resource) from Resource to Resource
{
	inline public function new(resource:Resource)
	{
		this = resource;
	}
	
	public var texture(get, set):Texture;
	inline function get_texture() return this.texture;
	inline function set_texture(v:Texture) return this.texture = v;
	
	public var atlas(get, set):TextureAtlas;
	inline function get_atlas() return this.atlas;
	inline function set_atlas(v:TextureAtlas) return this.atlas = v;
	
}