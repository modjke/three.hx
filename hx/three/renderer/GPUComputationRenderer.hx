package js.three;
import js.Three;
import js.html.Float32Array;
import js.three.DataTexture;

/**
 * @author yomboprime https://github.com/yomboprime
 *
 * GPUComputationRenderer, based on SimulationRenderer by zz85
 *
 * The GPUComputationRenderer uses the concept of variables. These variables are RGBA float textures that hold 4 floats
 * for each compute element (texel)
 *
 * Each variable has a fragment shader that defines the computation made to obtain the variable in question.
 * You can use as many variables you need, and make dependencies so you can use textures of other variables in the shader
 * (the sampler uniforms are added automatically) Most of the variables will need themselves as dependency.
 *
 * The renderer has actually two render targets per variable, to make ping-pong. Textures from the current frame are used
 * as inputs to render the textures of the next frame.
 *
 * The render targets of the variables can be used as input textures for your visualization shaders.
 *
 * Variable names should be valid identifiers and should not collide with THREE GLSL used identifiers.
 * a common approach could be to use 'texture' prefixing the variable name; i.e texturePosition, textureVelocity...
 *
 * The size of the computation (sizeX * sizeY) is defined as 'resolution' automatically in the shader. For example:
 * #DEFINE resolution vec2( 1024.0, 1024.0 )
 *
 * -------------
 *
 * Basic use:
 *
 * // Initialization...
 *
 * // Create computation renderer
 * var gpuCompute = new GPUComputationRenderer( 1024, 1024, renderer );
 *
 * // Create initial state float textures
 * var pos0 = gpuCompute.createTexture();
 * var vel0 = gpuCompute.createTexture();
 * // and fill in here the texture data...
 *
 * // Add texture variables
 * var velVar = gpuCompute.addVariable( "textureVelocity", fragmentShaderVel, pos0 );
 * var posVar = gpuCompute.addVariable( "texturePosition", fragmentShaderPos, vel0 );
 *
 * // Add variable dependencies
 * gpuCompute.setVariableDependencies( velVar, [ velVar, posVar ] );
 * gpuCompute.setVariableDependencies( posVar, [ velVar, posVar ] );
 *
 * // Add custom uniforms
 * velVar.material.uniforms.time = { value: 0.0 };
 *
 * // Check for completeness
 * var error = gpuCompute.init();
 * if ( error !== null ) {
 *		console.error( error );
  * }
 *
 *
 * // In each frame...
 *
 * // Compute!
 * gpuCompute.compute();
 *
 * // Update texture uniforms in your visualization materials with the gpu renderer output
 * myMaterial.uniforms.myTexture.value = gpuCompute.getCurrentRenderTarget( posVar ).texture;
 *
 * // Do your rendering
 * renderer.render( myScene, myCamera );
 *
 * -------------
 *
 * Also, you can use utility functions to create ShaderMaterial and perform computations (rendering between textures)
 * Note that the shaders can have multiple input textures.
 *
 * var myFilter1 = gpuCompute.createShaderMaterial( myFilterFragmentShader1, { theTexture: { value: null } } );
 * var myFilter2 = gpuCompute.createShaderMaterial( myFilterFragmentShader2, { theTexture: { value: null } } );
 *
 * var inputTexture = gpuCompute.createTexture();
 *
 * // Fill in here inputTexture...
 *
 * myFilter1.uniforms.theTexture.value = inputTexture;
 *
 * var myRenderTarget = gpuCompute.createRenderTarget();
 * myFilter2.uniforms.theTexture.value = myRenderTarget.texture;
 *
 * var outputRenderTarget = gpuCompute.createRenderTarget();
 *
 * // Now use the output texture where you want:
 * myMaterial.uniforms.map.value = outputRenderTarget.texture;
 *
 * // And compute each frame, before rendering to screen:
 * gpuCompute.doRenderTarget( myFilter1, myRenderTarget );
 * gpuCompute.doRenderTarget( myFilter2, outputRenderTarget );
 * 
 *
 *
 * @param {int} sizeX Computation problem size is always 2d: sizeX * sizeY elements.
 * @param {int} sizeY Computation problem size is always 2d: sizeX * sizeY elements.
 * @param {WebGLRenderer} renderer The renderer
  */

/**
 * Ported to haxe by
 * @author ignatiev <ignatiev.work@gmail.com>
 */
class GPUComputationRenderer 
{
	public var width(default, null):Int;
	public var height(default, null):Int;
	var renderer:WebGLRenderer;
	var variables:Array<Variable>;
	var mesh:Mesh;
	var scene:Scene;
	var camera:Camera;
	var currentTextureIndex:Int;
	
	var passThruUniforms = {
		texture: { value: null }
	};

	var passThruShader:ShaderMaterial;
	
	public function new(width:Int, height:Int, renderer:WebGLRenderer) 
	{
		this.width = width;
		this.height = height;
		this.renderer = renderer;
		
		this.variables = [];

		this.currentTextureIndex = 0;

		scene = new Scene();

		camera = new Camera();
		camera.position.z = 1;

		
		passThruShader = createShaderMaterial( getPassThroughFragmentShader(), passThruUniforms );

		mesh = new Mesh( new PlaneBufferGeometry( 2, 2 ), passThruShader );
		scene.add( mesh );
	}
	
	public function addVariable(variableName:String, computeFragmentShader:String, initialValueTexture:Texture):Variable
	{
		var material = this.createShaderMaterial( computeFragmentShader );

		var variable = {
			name: variableName,
			initialValueTexture: initialValueTexture,
			material: material,
			dependencies: null,
			renderTargets: [],
			wrapS: Three.ClampToEdgeWrapping,
			wrapT: Three.ClampToEdgeWrapping,
			minFilter: Three.NearestFilter,
			magFilter: Three.NearestFilter
		};

		this.variables.push( variable );

		return variable;
	}
	
	public function setVariableDependencies( variable:Variable, dependencies:Array<Variable> ) 
	{
		variable.dependencies = dependencies;
	};
	
	public function init() {

		if ( ! renderer.extensions.get( "OES_texture_float" ) ) {

			throw "No OES_texture_float support for float textures.";

		}

		if ( renderer.capabilities.maxVertexTextures == 0 ) {

			throw "No support for vertex shader textures.";

		}

		for ( i in 0...variables.length ) {

			var variable = this.variables[ i ];

			// Creates rendertargets and initialize them with input texture
			variable.renderTargets[ 0 ] = this.createRenderTarget( width, height, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter );
			variable.renderTargets[ 1 ] = this.createRenderTarget( width, height, variable.wrapS, variable.wrapT, variable.minFilter, variable.magFilter );
			this.renderTexture( variable.initialValueTexture, variable.renderTargets[ 0 ] );
			this.renderTexture( variable.initialValueTexture, variable.renderTargets[ 1 ] );

			// Adds dependencies uniforms to the ShaderMaterial
			var material = variable.material;
			var uniforms = material.uniforms;
			if ( variable.dependencies != null ) {

				for ( d in 0...variable.dependencies.length ) {

					var depVar = variable.dependencies[ d ];

					if ( depVar.name != variable.name ) {

						// Checks if variable exists
						var found = false;
						for ( j in 0...variables.length ) {

							if ( depVar.name == this.variables[ j ].name ) {
								found = true;
								break;
							}

						}
						if ( ! found ) {
							throw "Variable dependency not found. Variable=" + variable.name + ", dependency=" + depVar.name;
						}

					}

					
					uniforms[ depVar.name ] = { value: null };

					material.fragmentShader = "\nuniform sampler2D " + depVar.name + ";\n" + material.fragmentShader;

				}
			}
		}

		this.currentTextureIndex = 0;


	};

	public function compute() {

		var currentTextureIndex = this.currentTextureIndex;
		var nextTextureIndex = this.currentTextureIndex == 0 ? 1 : 0;

		for ( i in 0...variables.length ) {

			var variable = this.variables[ i ];

			// Sets texture dependencies uniforms
			if ( variable.dependencies != null ) {

				var uniforms = variable.material.uniforms;
				for ( d in 0...variable.dependencies.length ) {

					var depVar = variable.dependencies[ d ];

					uniforms[ depVar.name ].value = depVar.renderTargets[ currentTextureIndex ].texture;

				}

			}

			// Performs the computation for this variable
			this.doRenderTarget( variable.material, variable.renderTargets[ nextTextureIndex ] );

		}

		this.currentTextureIndex = nextTextureIndex;
	};

	public function getCurrentRenderTarget( variable:Variable ) {

		return variable.renderTargets[ this.currentTextureIndex ];

	};

	public function getAlternateRenderTarget( variable:Variable  ) {

		return variable.renderTargets[ this.currentTextureIndex == 0 ? 1 : 0 ];

	};

	function addResolutionDefine( materialShader:ShaderMaterial ) {

		materialShader.defines.resolution = 'vec2( ' + width + ', ' + height + " )";

	}

	// The following functions can be used to compute things manually

	function createShaderMaterial( computeFragmentShader:String, ?uniforms:Dynamic ):ShaderMaterial {

		if (uniforms == null) uniforms = {};

		var material = new ShaderMaterial( {
			uniforms: uniforms,
			vertexShader: getPassThroughVertexShader(),
			fragmentShader: computeFragmentShader
		} );

		addResolutionDefine( material );

		return material;
	}

	function createRenderTarget ( ?textureWidth:Int, ?textureHeight, ?wrapS:Wrapping, ?wrapT:Wrapping, ?minFilter:TextureFilter, ?magFilter:TextureFilter ) {

		if (textureWidth == null) textureWidth = width;
		if (textureHeight == null) textureHeight = height;
		
		if (wrapS == null) wrapS == Three.ClampToEdgeWrapping;
		if (wrapT == null) wrapT == Three.ClampToEdgeWrapping;

		if (minFilter == null) minFilter = Three.NearestFilter;
		if (magFilter == null) magFilter = Three.NearestFilter;

		var renderTarget = new WebGLRenderTarget( textureWidth, textureHeight, {
			wrapS: wrapS,
			wrapT: wrapT,
			minFilter: minFilter,
			magFilter: magFilter,
			format: Three.RGBAFormat,
			type: ( ~/(iPad|iPhone|iPod)/.match( Browser.navigator.userAgent ) ) ? Three.HalfFloatType : Three.FloatType,
			stencilBuffer: false
		} );

		return renderTarget;

	};

	public function createTexture ( ?textureWidth:Int, ?textureHeight:Int, ?data:Float32Array):DataTexture {

		if (textureWidth == null) textureWidth = width;
		if (textureHeight == null) textureHeight = height;
				
		var dataLength = textureWidth * textureHeight * 4;
		if (data == null) 
			data = new Float32Array( dataLength );
		else 		
			if (data.length != dataLength) throw "Invalid data length";
		
		var texture = new DataTexture( data, textureWidth, textureHeight, Three.RGBAFormat, Three.FloatType, Three.UVMapping, Three.ClampToEdgeWrapping, Three.ClampToEdgeWrapping );
		texture.needsUpdate = true;

		return texture;

	};


	function renderTexture( input:Texture, output:WebGLRenderTarget ) {

		// Takes a texture, and render out in rendertarget
		// input = Texture
		// output = RenderTarget

		passThruUniforms.texture.value = input;

		this.doRenderTarget( passThruShader, output);

		passThruUniforms.texture.value = null;

	};

	function doRenderTarget ( material:ShaderMaterial, output:WebGLRenderTarget) {

		mesh.material = material;
		renderer.render( scene, camera, output );
		mesh.material = passThruShader;

	};

	// Shaders

	public inline function getPassThroughVertexShader() {

		return	'
			void main()	{				
				gl_Position = vec4( position, 1.0 );				
			}
		';

	}

	public inline function getPassThroughFragmentShader() {

		return	'
			uniform sampler2D texture;
			
			void main() {				
				vec2 uv = gl_FragCoord.xy / resolution.xy;				
				gl_FragColor = texture2D( texture, uv );				
			}
		';

	}
	
}

@:noCompletion
typedef Variable = {
	name: String,
	initialValueTexture: Texture,
	material: ShaderMaterial,
	dependencies: Array<Variable>,
	renderTargets: Array<WebGLRenderTarget>,
	wrapS: Wrapping,
	wrapT: Wrapping,
	minFilter: TextureFilter,
	magFilter: TextureFilter
}