package hx.three.loader.englercj;
import haxe.io.Path;
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr.Field;

class LoaderInclude 
{

	static var included = false;
	public static function include():Array<Field>
	{
		if (!included)
		{
			included = true;
			
			var file = Context.getPosInfos(Context.currentPos()).file;
			var dir = Path.directory(file);
			Compiler.includeFile(Path.join([dir, "resource-loader.min.js"]), Top);
		}
		
		
		return null;
	}
	
	
}