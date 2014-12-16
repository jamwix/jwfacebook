package com.jamwix;


import android.app.Activity;
import android.content.res.AssetManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.opengl.GLSurfaceView;
import android.util.Log;

import org.haxe.extension.Extension;
import org.haxe.lime.HaxeObject;

import com.facebook.*;
import com.facebook.model.GraphObject;
import com.facebook.model.GraphPlace;
import com.facebook.model.GraphUser;
import com.facebook.widget.*;

import java.io.File;
import java.util.List;
import java.io.BufferedInputStream;
import java.io.FilterInputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Arrays;
/* 
	You can use the Android Extension class in order to hook
	into the Android activity lifecycle. This is not required
	for standard Java code, this is designed for when you need
	deeper integration.
	
	You can access additional references from the Extension class,
	depending on your needs:
	
	- Extension.assetManager (android.content.res.AssetManager)
	- Extension.callbackHandler (android.os.Handler)
	- Extension.mainActivity (android.app.Activity)
	- Extension.mainContext (android.content.Context)
	- Extension.mainView (android.view.View)
	
	You can also make references to static or instance methods
	and properties on Java classes. These classes can be included 
	as single files using <java path="to/File.java" /> within your
	project, or use the full Android Library Project format (such
	as this example) in order to include your own AndroidManifest
	data, additional dependencies, etc.
	
	These are also optional, though this example shows a static
	function for performing a single task, like returning a value
	back to Haxe from Java.
*/
public class JWFacebook extends Extension {
	
    private static String _appId;
	private static HaxeObject _callback = null;
	private static GLSurfaceView _mSurface;

	public static void initialize (String appId, HaxeObject callback) {
        _callback = callback;
        _appId = appId;

		_mSurface = (GLSurfaceView) Extension.mainActivity.getCurrentFocus();
    }

	public static void connect() {
        Session session = createSession( );
        if ( session.isOpened( ) ) {
            return;
        }
        Session.OpenRequest req = createOpenRequest( session );
        if ( SessionState.CREATED_TOKEN_LOADED.equals(session.getState()) || 
             !SessionState.OPENING.equals(session.getState()) ) {
            try{
                session.openForRead(req);
            } catch( Exception e) {
                e.printStackTrace();
            }
        }
        return;
    }

    public static void postPhoto(String path, String msg) {
        final Session session = createSession();
        final String fPath = path;
        final String fMsg = msg;
        if (session.isOpened()) {
            if (session.isPermissionGranted("publish_actions")) {
                doPhotoRequest(session, path, msg);
            } else {
                Session.NewPermissionsRequest req = createRequestFromString("publish_actions");
                req.setCallback( new Session.StatusCallback( ){
                    @Override
                    public void call( final Session session, final SessionState state, final Exception exception) {
                        if( state.equals( SessionState.CLOSED_LOGIN_FAILED )
                            || state.equals( SessionState.CLOSED ) ) {
                            session.closeAndClearTokenInformation();
                            _callback.call( "onOpened", new Object[] { "ERROR", session.getAccessToken() });
                        } else {
                            doPhotoRequest(session, fPath, fMsg);
                        }
                    }
                });
                session.requestNewPublishPermissions(req);
            }
        } else {
            Session.OpenRequest req = createOpenRequest( session );
            req.setPermissions(createPermissionsFromString("publish_actions"));
            req.setCallback( new Session.StatusCallback( ){
                @Override
                public void call( final Session session, final SessionState state, final Exception exception) {
                    if( state.equals( SessionState.CLOSED_LOGIN_FAILED )
                        || state.equals( SessionState.CLOSED ) ) {
                        session.closeAndClearTokenInformation();
                        _callback.call( "onOpened", new Object[] { "ERROR", session.getAccessToken() });
                    } else {
                        doPhotoRequest(session, fPath, fMsg);
                    }
                }
            });

            try {
                session.openForPublish(req);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
    }

    private static void doPhotoRequest(Session session, String path, String msg) {
        File file = new File(path);
        
        int size = (int)file.length();
        byte[] bytes = new byte[size];
        try {
            BufferedInputStream buf = new BufferedInputStream(new FileInputStream(file));
            buf.read(bytes, 0, bytes.length);
            buf.close();
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return;
        } catch (IOException e) {
            e.printStackTrace();
            return;
        }

        Log.i("trace", "Posting photo at: " + path);
        Bundle params = new Bundle();
        params.putString("message", msg);
        params.putByteArray("source", bytes);

        final Request req = new Request(session, "me/photos", params, HttpMethod.POST, graphCb());
        _mSurface.queueEvent(new Runnable() {
            @Override
            public void run() {
                Log.i("trace", "Executing postPhoto");
                req.executeAndWait();
            }
        });
    }

    private static Request.Callback graphCb() { 
        
        return new Request.Callback( ){

            @Override
            public void onCompleted(Response response) {

                String sGraphPath = response.getRequest( ).getGraphPath( );

                FacebookRequestError error = response.getError( );
                if( error != null ){
                    Log.e("trace", "Error posting photo: " + error.toString());
                    _callback.call("onGraph", new Object[]{"GRAPH_ERROR", sGraphPath, error.toString()} );
                }else{
                    Log.i("trace", "Photo posted!!");
                    _callback.call("onGraph", new Object[]{"GRAPH_SUCCESS", sGraphPath, response.getGraphObject().getInnerJSONObject().toString()});
                }

            }
        };
    }

    private static Session createSession() {
        Session session = Session.getActiveSession();
        if ( session != null && !SessionState.CLOSED.equals(session.getState())
            && !SessionState.CLOSED_LOGIN_FAILED.equals(session.getState())) {
            session = Session.getActiveSession();
        } else {
            session = new Session.Builder( Extension.mainActivity ).setApplicationId(_appId).build();
            Session.setActiveSession( session );
        }
        return session;
    }

    private static Session.OpenRequest createOpenRequest(Session session) {
        Session.OpenRequest req = new Session.OpenRequest(Extension.mainActivity);
        req.setCallback( new Session.StatusCallback( ){
            @Override
            public void call( final Session session, final SessionState state, final Exception exception) {
                if (exception != null) {
                    Log.e("trace", "FB OpenRequest Problem: " + exception.getMessage());
                    return;
                }

                Log.i("trace", "SESSION: " + session + " STATE: " + state + "EXP: " + exception);
                if( state.equals( SessionState.CLOSED_LOGIN_FAILED )
                    || state.equals( SessionState.CLOSED ) ) {
                    session.closeAndClearTokenInformation();
                    _callback.call( "onOpened", new Object[] { "ERROR", session.getAccessToken() });
                } else if (state.equals(SessionState.OPENING)) {
                    Log.i("trace", "Opening FB session: " + session);
                } else {
                    _callback.call( "onOpened", new Object[] { "OPENED", session.getAccessToken() });
                }
            }
        });
        return req;
    }

    private static Session.NewPermissionsRequest createRequestFromString( String sPerms ) {
        List<String> permissions = createPermissionsFromString( sPerms );
        Session.NewPermissionsRequest req = new Session.NewPermissionsRequest( Extension.mainActivity , permissions );
        return req;
    }

    private static List<String> createPermissionsFromString( String sPerms ) {
        String[] aPerms = sPerms.split("&");
        List<String> permissions = Arrays.asList( aPerms );
        return permissions;
    }
// init
// connect 
// disconnect   
// post photo
// request publish
	
	/**
	 * Called when an activity you launched exits, giving you the requestCode 
	 * you started it with, the resultCode it returned, and any additional data 
	 * from it.
	 */
	public boolean onActivityResult (int requestCode, int resultCode, Intent data) {
        Session session = Session.getActiveSession( );
        if( session != null ) {
			session.onActivityResult(Extension.mainActivity, requestCode, resultCode, data);
        }
		return true;
	}
	

	
	/**
	 * Called when the activity is starting.
	 */
	public void onCreate (Bundle savedInstanceState) {
        //uiHelper = new UiLifecycleHelper(this.mainActivity, callback);
        //uiHelper.onCreate(savedInstanceState);
	}
	
	
	/**
	 * Perform any final cleanup before an activity is destroyed.
	 */
	public void onDestroy () {
		
		
		
	}
	
	
	/**
	 * Called as part of the activity lifecycle when an activity is going into
	 * the background, but has not (yet) been killed.
	 */
	public void onPause () {
        //uiHelper.onPause();
	}
	
	
	/**
	 * Called after {@link #onStop} when the current activity is being 
	 * re-displayed to the user (the user has navigated back to it).
	 */
	public void onRestart () {
		
		
		
	}
	
	
	/**
	 * Called after {@link #onRestart}, or {@link #onPause}, for your activity 
	 * to start interacting with the user.
	 */
	public void onResume () {
        //uiHelper.onResume();
		
		
	}
	
	
	/**
	 * Called after {@link #onCreate} &mdash; or after {@link #onRestart} when  
	 * the activity had been stopped, but is now again being displayed to the 
	 * user.
	 */
	public void onStart () {
		
		
		
	}
	
	
	/**
	 * Called when the activity is no longer visible to the user, because 
	 * another activity has been resumed and is covering this one. 
	 */
	public void onStop () {
		
		
		
	}
	
	
}
