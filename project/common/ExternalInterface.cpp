#ifndef STATIC_LINK
#define IMPLEMENT_API
#endif

#if defined(HX_WINDOWS) || defined(HX_MACOS) || defined(HX_LINUX)
#define NEKO_COMPATIBLE
#endif

#include <hx/CFFI.h>
#include <stdio.h>
#include "JWFacebook.h"

using namespace jwfacebook;


AutoGCRoot* fb_event_handle = 0;

static value jwfacebook_set_event_handle(value onEvent)
{
	fb_event_handle = new AutoGCRoot(onEvent);
	return alloc_null();
}
DEFINE_PRIM(jwfacebook_set_event_handle, 1);


static value jwfacebook_initialize() 
{
	#ifdef IPHONE
	jw_init();
	#endif
	return alloc_null();
}
DEFINE_PRIM (jwfacebook_initialize, 0);


static value jwfacebook_connect(value appID, value allowUI) 
{
	#ifdef IPHONE
	jw_connect(val_string(appID), val_bool(allowUI));
	#endif
	return alloc_null();
}
DEFINE_PRIM (jwfacebook_connect, 2);

static value jwfacebook_disconnect() 
{
	#ifdef IPHONE
	jw_disconnect();
	#endif
	return alloc_null();
}
DEFINE_PRIM (jwfacebook_disconnect, 0);

static value jwfacebook_request_publish_actions() 
{
	#ifdef IPHONE
	jw_request_publish_actions();
	#endif
	return alloc_null();
}
DEFINE_PRIM (jwfacebook_request_publish_actions, 0);

static value jwfacebook_post_photo(value path, value msg) 
{
	#ifdef IPHONE
	jw_post_photo(val_string(path), val_string(msg));
	#endif
	return alloc_null();
}
DEFINE_PRIM (jwfacebook_post_photo, 2);

extern "C" void jwfacebook_main() 
{
	val_int(0); // Fix Neko init
}
DEFINE_ENTRY_POINT(jwfacebook_main);

extern "C" int jwfacebook_register_prims() { return 0; }

extern "C" void send_fb_event(const char* type, const char* data)
{
    value o = alloc_empty_object();
    alloc_field(o,val_id("type"),alloc_string(type));
	
    if (data != NULL) alloc_field(o,val_id("data"),alloc_string(data));
	
    val_call1(fb_event_handle->get(), o);
}

