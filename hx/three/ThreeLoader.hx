package hx.three;
import haxe.ds.StringMap;
import js.three.LoadingManager;
import js.three.Texture;
import js.three.TextureLoader;

class ThreeLoader 
{
	var textureLoader:TextureLoader;
	var textures:StringMap<Texture> = new StringMap();
	public function new(?manager:LoadingManager) 
	{
		textureLoader = new TextureLoader(manager);
	}
	
	public function getTexture(url:String) return textures.get(url);
	
	public function loadTexture(url:String, ?onLoaded:Texture->Void):Texture
	{
		return textureLoader.load(url, function (texture)
		{
			this.textures.set(url, texture);
			
			if (onLoaded != null)
				onLoaded(texture);
		});
	}
	
	public function load(textures:Array<String>, onLoad:Void->Void)
	{
		var count = textures.length;
		for (url in textures)
		{			
			textureLoader.load(url, function (texture)
			{
				this.textures.set(url, texture);
				count--;
				
				if (count == 0)
					onLoad();
			});
		}
		
	}
}