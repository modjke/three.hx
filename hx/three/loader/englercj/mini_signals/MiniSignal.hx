package hx.three.loader.englercj.mini_signals;
import haxe.Constraints.Function;
import hx.three.loader.englercj.mini_signals.MiniSignal.MiniSignalBinding;

/* https://github.com/Hypercubed/mini-signals/blob/master/API.md */

/* Api: private */
extern class MiniSignalBinding
{
}

extern class MiniSignal 
{

	function new();
	
	@:overload(function (exists:Bool):Bool {})
	function handlers():Array<MiniSignalBinding>;
	
	function has(node:MiniSignalBinding):Bool;
	function dispatch(param:haxe.extern.Rest<Any>):Bool;
	function add(fn:Function, ?thisArg:Any):MiniSignalBinding;
	function once(fn:Function, ?thisArg:Any):MiniSignalBinding;
	function detach(node:MiniSignalBinding):MiniSignal;
	function detachAll():MiniSignal;
}