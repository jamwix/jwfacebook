package com.jamwix;

import openfl.Lib;
import openfl.events.EventDispatcher;
import openfl.events.Event;

class JWFacebook 
{
	private static var initialized = false;
	private static var dispatcher = new EventDispatcher ();

	public static function init():Void
	{
		#if ios
		
		if (!initialized) 
		{
			set_event_handle(notifyListeners);
		}

		fb_initialize();
		initialized = true;

		#end
	}

	public static function connect(appID:String, allowUI:Bool):Void
	{
		#if ios
		fb_connect(appID, allowUI);
		#end
	}
	
	public static function requstPublishActions():Void
	{
		#if ios
		fb_request_publish_actions();
		#end
	}

	public static function postPhoto(path:String, msg:String):Void
	{
		#if ios
		fb_post_photo(path, msg);
		#end
	}

	private static function notifyListeners(inEvent:Dynamic):Void
	{
		
		#if ios
		
		var type = Std.string (Reflect.field (inEvent, "type"));
		var data = Std.string (Reflect.field (inEvent, "data"));
		
		switch (type) {
			
			case "ERROR":
				
				dispatchEvent(new JWFacebookEvent(JWFacebookEvent.ERROR, data));
			
			case "OPENED":
				
				dispatchEvent(new JWFacebookEvent(JWFacebookEvent.OPENED, data));

			case "PUBLISH_ALLOWED":

				dispatchEvent(
					new JWFacebookEvent(JWFacebookEvent.PUBLISH_ALLOWED, data));
			
			case "PUBLISH_DENIED":

				dispatchEvent(
					new JWFacebookEvent(JWFacebookEvent.PUBLISH_DENIED, data));

			case "GRAPH_SUCCESS":

				dispatchEvent(
					new JWFacebookEvent(JWFacebookEvent.GRAPH_SUCCESS, data));

			case "GRAPH_ERROR":

				dispatchEvent(
					new JWFacebookEvent(JWFacebookEvent.GRAPH_ERROR, data));

			default:
			
		}

		#end
	}

	public static function dispatchEvent (event:Event):Bool {
		return dispatcher.dispatchEvent (event);
	}
	
	public static function addEventListener (type:String, listener:Dynamic):Void {
		dispatcher.addEventListener(type, listener);
	}

	public static function removeEventListener (type:String, listener:Dynamic):Void {
		dispatcher.removeEventListener(type, listener);
	}

	// Native methods

	#if ios
	private static var fb_initialize = Lib.load("jwfacebook", "jwfacebook_initialize", 0);
	private static var fb_connect = Lib.load("jwfacebook", "jwfacebook_connect", 2);
	private static var fb_disconnect = Lib.load("jwfacebook", "jwfacebook_disconnect", 0);
	private static var set_event_handle = Lib.load ("jwfacebook", "jwfacebook_set_event_handle", 1);
	private static var fb_request_publish_actions = 
		Lib.load("jwfacebook", "jwfacebook_request_publish_actions", 0);
	private static var fb_post_photo = 
		Lib.load("jwfacebook", "jwfacebook_post_photo", 2);

	#end
}
	
