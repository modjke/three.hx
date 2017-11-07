package hx.three.loader.englercj;

import haxe.DynamicAccess;


@:native("Loader.Resource.LOAD_TYPE")
@:enum extern abstract LoadType(Int) {
	var XHR; 
	var IMAGE; 
	var AUDIO; 
	var VIDEO;
}

@:native("Loader.Resource.TYPE")
@:enum extern abstract ResourceType(Int) {
	var JSON; 
	var XML; 
	var IMAGE; 
	var AUDIO; 
	var VIDEO;
}

@:native("Loader.Resource.XHR_RESPONSE_TYPE")
@:enum extern abstract XhrResponseType(Int) {
	var DEFAULT; 
	var BUFFER; 
	var BLOB; 
	var DOCUMENT; 
	var JSON; 
	var TEXT;
}

@:native("Loader.Resource")
extern class Resource implements Dynamic {
	
	/**
	 * Manages the state and loading of a single resource represented by
	 * a single URL.
	 *
	 * @class
	 * @param name {string} The name of the resource to load.
	 * @param url {string|string[]} The url for this resource, for audio/video loads you can pass an array of sources.
	 * @param [options] {object} The options for the load.
	 * @param [options.crossOrigin] {boolean} Is this request cross-origin? Default is to determine automatically.
	 * @param [options.loadType=Resource.LOAD_TYPE.XHR] {Resource.LOAD_TYPE} How should this resource be loaded?
	 * @param [options.xhrType=Resource.XHR_RESPONSE_TYPE.DEFAULT] {Resource.XHR_RESPONSE_TYPE} How should the data being
	 *      loaded be interpreted when using XHR?
	 */
	function new(name:String, url:String, ?options:Loader.LoaderOptions);

	var metadata:Any;

	var type:ResourceType;
	
	/**
	 * Since plugins like Spine can add additional fields to Resource
	 * we need somewhat 'typed' method to retrieve those fields.	 
	 * 
	 * var data:SpineData = resource.get("spineData");
	 */
	inline function get<T>(name:String):T {
		return untyped this[name];
	}

	/**
	 * Extension of this resource
	 * @member {string}
	 */

	var extension:String;
	/**
     * The name of this resource.
     *
     * @member {string}
     * @readonly
     */
	var name:String;

	/**
     * The url used to load this resource.
     *
     * @member {string}
     * @readonly
     */
	var url:String;

	/**
     * The data that was loaded by the resource.
     *
     * @member {any}
     */
	var data:Dynamic;

	/**
     * The XHR object that was used to load this resource. This is only set
     * when `loadType` is `Resource.LOAD_TYPE.XHR`.
     *
     * @member {XMLHttpRequest}
     */
	var xhr:Dynamic;

	/**
     * The type used to load the resource via XHR. If unset, determined automatically.
     *
     * @member {String}
     */
	var xhrType:String;

	/**
     * Is this request cross-origin? If unset, determined automatically.
     *
     * @member {string}
     */
	var crossOrigin:String;

	/**
     * The method of loading to use for this resource.
     *
     * @member {Resource.LOAD_TYPE}
     */
	var loadType:LoadType;

	/**
     * The error that occurred while loading (if any).
     *
     * @member {Error}
     * @readonly
     */
	var error:Dynamic;
}
