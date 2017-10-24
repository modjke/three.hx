package hx.three;

@:forward
abstract UniformValue<T>({value:T}) to {value:T}
{
	@:from 
	public static function fromValue<T>(value:T):UniformValue<T>
	{
		return new UniformValue(value);
	}
	
	public function new(?value:T)
	{
		this = { value: value };
	}
}