#import <CoreFoundation/CoreFoundation.h>
#import <UIKit/UIKit.h>
#include <JWFacebook.h>
#import <FacebookSDK.h>

extern "C" void send_fb_event(const char* type, const char* data);

@interface NMEAppDelegate: NSObject <UIApplicationDelegate>
@end
	
@interface JWFacebook: NSObject
- (id) init;
- (bool) connect: (NSString*) NSappID 
          withUI: (BOOL) withUI;
- (void) disconnect;
- (void) fbRequest:(NSString*)NSGraphRequest
        HTTPMethod:(NSString*)HTTPMethod
        parameters:(NSDictionary*)parameters;
- (void) requstPublishActions;
- (void) postPhoto:(NSString*) path withMessage:(NSString*) msg;
@end

@implementation NMEAppDelegate (Facebook)
    - (BOOL) application:(UIApplication *) application
                         openURL:(NSURL *)url
                         sourceApplication:(NSString *)sourceApplication
                         annotation:(id)annotation 
    {
        BOOL handled = [FBAppCall handleOpenURL:url
                         sourceApplication:sourceApplication];
        return handled;
    }
@end

@implementation JWFacebook

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter]
        removeObserver:self	name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter]
        removeObserver:self	name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (id) init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(willTerminate:)
            name:UIApplicationWillTerminateNotification
            object:nil
        ];
        [[NSNotificationCenter defaultCenter]
            addObserver:self
            selector:@selector(didBecomeActive:)
            name:UIApplicationDidBecomeActiveNotification
            object:nil
        ];
    }
    return self;
}

- (void) willTerminate: (NSNotification *) notification {
    [FBSession.activeSession close];
}

- (void) didBecomeActive: (NSNotification *) notification {
    [FBSession.activeSession handleDidBecomeActive];
}

- (bool) connect: (NSString*) NSappID 
          withUI: (BOOL) withUI 
{
    NSLog(@"connect with id: %@",NSappID);
    [FBSettings setDefaultAppID:NSappID];
    [FBSession openActiveSessionWithReadPermissions: nil
        allowLoginUI:withUI
        completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
            [self sessionStateChanged:session state:state error:error];
        }
    ];
    return [FBSession.activeSession isOpen];
}

- (void) disconnect
{
    [FBSession.activeSession closeAndClearTokenInformation];
}

- (void) requstPublishActions 
{
    if ([[FBSession activeSession].permissions containsObject:@"publish_actions"])
    {
        send_fb_event("PUBLISH_ALLOWED", "");
    }

    [FBSession.activeSession requestNewPublishPermissions:@[@"publish_actions"]
        defaultAudience:FBSessionDefaultAudienceEveryone
        completionHandler:^(FBSession *session, NSError *error){
            if ( error ) {
                send_fb_event("PUBLISH_DENIED", [error.localizedDescription UTF8String]);
                return;
            }

            send_fb_event("PUBLISH_ALLOWED", "");
        }
    ];
}

- (void) fbRequest:(NSString*)NSGraphRequest
        HTTPMethod:(NSString*)HTTPMethod
        parameters:(NSDictionary*)parameters {
    
    [FBRequestConnection startWithGraphPath:NSGraphRequest
        parameters:parameters
        HTTPMethod:HTTPMethod
        completionHandler:^(FBRequestConnection *connection, id result, NSError *error){
            if ( error ) {
                send_fb_event(
                    "GRAPH_ERROR", [error.localizedDescription UTF8String]);
            } else {
                send_fb_event("GRAPH_SUCCESS", "");
            }
        }
    ];
}

- (void) postPhoto:(NSString*) path withMessage:(NSString*) msg
{
    UIImage *image = [UIImage imageWithContentsOfFile: path];

    if (!image) {
        NSLog(@"No image file found at %@", path);
        return;
    }

    NSDictionary *parameters = 
        [NSDictionary dictionaryWithObjectsAndKeys: image, @"source",
                                                    msg, @"message",
                                                    nil];

    if ([[FBSession activeSession] isOpen]) {
        if ([[[FBSession activeSession] permissions] indexOfObject:@"publish_actions"] == NSNotFound) {

            [[FBSession activeSession] requestNewPublishPermissions:[NSArray arrayWithObject:@"publish_actions"] 
                                                    defaultAudience:FBSessionDefaultAudienceFriends
                                                  completionHandler:^(FBSession *session,NSError *error){
                                                        [self
                                                            fbRequest: @"me/photos"
                                                            HTTPMethod: @"POST"
                                                            parameters: parameters];
                                                  }];

        } else {
            [self
                fbRequest: @"me/photos"
                HTTPMethod: @"POST"
                parameters: parameters];
        }
    } else {
        [FBSession openActiveSessionWithPublishPermissions:[NSArray arrayWithObject:@"publish_actions"]
                                           defaultAudience:FBSessionDefaultAudienceFriends
                                              allowLoginUI:YES
                                         completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                             if (!error && status == FBSessionStateOpen) {
                                                [self
                                                    fbRequest: @"me/photos"
                                                    HTTPMethod: @"POST"
                                                    parameters: parameters];
                                             } else {
                                                 NSLog(@"FB post photo error: %@", error.localizedDescription);
                                             }
                                         }];
    }
}

- (void) sessionStateChanged: (FBSession *)session
                       state: (FBSessionState) state
                       error: (NSError *)error 
{
    switch (state) {
        case FBSessionStateOpen:
            if (!error) {
                send_fb_event("OPENED" , [[[session accessTokenData] accessToken] UTF8String]);
            }
            break;
        case FBSessionStateClosed:
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            break;
        default:
            break;
    }

    if (error) {
        send_fb_event("ERROR", [error.localizedDescription UTF8String]);
    }
}

@end

extern "C"
{
	static JWFacebook* jwFacebook = nil;
    
	void jw_init()
    {
		jwFacebook = [[JWFacebook alloc] init];
	}

	bool jw_connect( const char *sAppID, bool allow_ui ){
		NSString *NSAppID = [ [NSString alloc] initWithUTF8String:sAppID ];
		NSLog(@"connect %@",NSAppID);
		BOOL ui = allow_ui ? YES : NO;
		return [jwFacebook connect:NSAppID withUI:ui];
	}

	void jw_disconnect()
    {
		[jwFacebook disconnect];
	}

	void jw_post_photo( const char *image_path, const char *message ){
		NSString *ns_image_path = 
            [[NSString alloc] initWithUTF8String: image_path];
		NSString *ns_message = [[NSString alloc] initWithUTF8String: message];

		[jwFacebook
            postPhoto: ns_image_path
          withMessage: ns_message];
	}

    void jw_request_publish_actions() {
        [jwFacebook requstPublishActions];
    }
}
