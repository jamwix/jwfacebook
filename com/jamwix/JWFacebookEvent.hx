package com.jamwix;

import openfl.events.Event;

class JWFacebookEvent extends Event 
{
	
	
	public static inline var ERROR = "ERROR";
	public static inline var OPENED = "OPENED";
	public static inline var PUBLISH_ALLOWED = "PUBLISH_ALLOWED";
	public static inline var PUBLISH_DENIED = "PUBLISH_DENIED";
	public static inline var GRAPH_SUCCESS = "GRAPH_SUCCESS";
	public static inline var GRAPH_ERROR = "GRAPH_ERROR";
	
	public var data:String;

	public function new (type:String, data:String = null) 
	{
		super(type);
		
		this.data = data;
	}
}

