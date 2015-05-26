#ifndef FACEBOOK_H
#define FACEBOOK_H

namespace jwfacebook
{	
    extern "C"
    {	
        void jw_init();
        bool jw_connect( const char *sAppID, bool allow_ui );
	    void jw_disconnect();
	    void jw_post_photo( const char *image_path, const char *message );
        void jw_request_publish_actions();
        void jwfb_logout();
        void jwfb_get_friends();
        void jwfb_get_me();
    }
}

#endif
