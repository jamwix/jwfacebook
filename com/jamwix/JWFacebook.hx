package com.jamwix;

import openfl.Lib;
import openfl.events.EventDispatcher;
import openfl.events.Event;

#if android
import openfl.utils.JNI;
#end

class JWFacebook 
{
	private static var initialized = false;
	private static var dispatcher = new EventDispatcher ();

#if android
	private static var funcInit:Dynamic;
	private static var funcConnect:Dynamic;
	private static var funcPostPhoto:Dynamic;
#end

	public static function init(?appId:String = null):Void
	{
		#if ios
		
		if (!initialized) 
		{
			set_event_handle(notifyListeners);
		}

		fb_initialize();
		#elseif android
		
		if (funcInit == null) {
			funcInit = JNI.createStaticMethod ("com/jamwix/JWFacebook", "initialize", "(Ljava/lang/String;Lorg/haxe/lime/HaxeObject;)V");
		}

		funcInit(appId, new FBHandler());

		#end
		initialized = true;
	}

	public static function connect(appID:String = null, allowUI:Bool = true):Void
	{
		#if ios
		fb_connect(appID, allowUI);
		#end
#if android
		if (funcConnect == null) {
			funcConnect = JNI.createStaticMethod ("com/jamwix/JWFacebook", "connect", "()V");
		}

		funcConnect();
#end
	}

	public static function profilePicUrl(fbId:String, width:Int = 100, 
										 height:Int = 100)
	{
		return "https://graph.facebook.com/" + fbId + "/picture";
	}

	public static function logout():Void
	{
#if ios
		fb_logout();
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

#if android
		if (funcPostPhoto == null) {
			funcPostPhoto = JNI.createStaticMethod ("com/jamwix/JWFacebook", "postPhoto", "(Ljava/lang/String;Ljava/lang/String;)V");
		}

		funcPostPhoto(path, msg);
#end
	}

	public static function getFriends():Void
	{
#if ios
		fb_get_friends();
#end
	}

	public static function getMe():Void
	{
#if ios
		fb_get_me();
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
	private static var fb_logout = Lib.load("jwfacebook", "jwfacebook_logout", 0);
	private static var fb_disconnect = Lib.load("jwfacebook", "jwfacebook_disconnect", 0);
	private static var set_event_handle = Lib.load ("jwfacebook", "jwfacebook_set_event_handle", 1);
	private static var fb_request_publish_actions = 
		Lib.load("jwfacebook", "jwfacebook_request_publish_actions", 0);
	private static var fb_post_photo = 
		Lib.load("jwfacebook", "jwfacebook_post_photo", 2);
	private static var fb_get_friends = 
		Lib.load("jwfacebook", "jwfacebook_get_friends", 0);
	private static var fb_get_me = Lib.load("jwfacebook", "jwfacebook_get_me", 0);

	#end
}

#if android

private class FBHandler 
{
	public function new ()
	{
	}

	public function onOpened(state:String, data:String):Void
	{
		if (state == "OPENED")
			JWFacebook.dispatchEvent(new JWFacebookEvent(JWFacebookEvent.OPENED, data));
		else
			JWFacebook.dispatchEvent(new JWFacebookEvent(JWFacebookEvent.ERROR, data));
	}

	public function onGraph(state:String, path:String, data:String):Void
	{
		if (state == "GRAPH_SUCCESS")
			JWFacebook.dispatchEvent(new JWFacebookEvent(JWFacebookEvent.GRAPH_SUCCESS, data));
		else
			JWFacebook.dispatchEvent(new JWFacebookEvent(JWFacebookEvent.GRAPH_ERROR, data));
	}
}
#end
	
