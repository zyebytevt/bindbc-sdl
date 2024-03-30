/*
This example creates an SDL window and renderer, and then draws some
textures to it every frame.

This code is public domain. Feel free to use it for any purpose!
*/

import bindbc.sdl;

//We will use this renderer to draw into this window every frame.
SDL_Window* window = null;
SDL_Renderer* renderer = null;
SDL_Texture* texture = null;
int textureWidth = 0;
int textureHeight = 0;

enum windowWidth = 640;
enum windowHeight = 480;

extern(C) nothrow:
mixin(makeSDLMain(dynLoad: q{
	if(!loadSDL()){
		import core.stdc.stdio, bindbc.loader;
		foreach(error; bindbc.loader.errors){
			printf("%s\n", error.message);
		}
	}}));

//This function runs once at startup.
SDL_AppResult SDL_AppInit(void** appState, int argC, char** argV){
	SDL_Surface* surface = null;
	char* bmpPath = null;
	
	if(!SDL_Init(SDL_InitFlags.video)){
		SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags.error, "Couldn't initialise SDL!", SDL_GetError(), null);
		return SDL_AppResult.failure;
	}
	
	if(!SDL_CreateWindowAndRenderer("examples/renderer/textures", windowWidth, windowHeight, 0, &window, &renderer)){
		SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags.error, "Couldn't create window/renderer!", SDL_GetError(), null);
		return SDL_AppResult.failure;
	}
	
	/*
	Textures are pixel data that we upload to the video hardware for fast drawing. Lots of 2D
	engines refer to these as "sprites." We'll do a static texture (upload once, draw many
	times) with data from a bitmap file.
	*/
	
	/*
	SDL_Surface is pixel data the CPU can access. SDL_Texture is pixel data the GPU can access.
	Load a .bmp into a surface, move it to a texture from there.
	*/
	SDL_asprintf(&bmpPath, "%s/../assets/sample.bmp", SDL_GetBasePath()); //allocate a string of the full file path
	surface = SDL_LoadBMP(bmpPath);
	if(!surface){
		SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags.error, "Couldn't load bitmap!", SDL_GetError(), null);
		return SDL_AppResult.failure;
	}
	
	SDL_free(bmpPath); //done with this, the file is loaded.
	
	textureWidth = surface.w;
	textureHeight = surface.h;
	
	texture = SDL_CreateTextureFromSurface(renderer, surface);
	if(!texture){
		SDL_ShowSimpleMessageBox(SDL_MessageBoxFlags.error, "Couldn't create static texture!", SDL_GetError(), null);
		return SDL_AppResult.failure;
	}
	
	SDL_DestroySurface(surface); //done with this, the texture has a copy of the pixels now.
	
	return SDL_AppResult.continue_; //carry on with the program!
}

//This function runs when a new event (mouse input, keypresses, etc) occurs.
SDL_AppResult SDL_AppEvent(void* appState, SDL_Event* event){
	if(event.type == SDL_EventType.quit){
		return SDL_AppResult.success; //end the program, reporting success to the OS.
	}
	return SDL_AppResult.continue_; //carry on with the program!
}

//This function runs once per frame, and is the heart of the program.
SDL_AppResult SDL_AppIterate(void* appState){
	SDL_FRect dstRect;
	const ulong now = SDL_GetTicks();
	
	//we'll have some textures move around over a few seconds.
	const float direction = ((now % 2_000) >= 1_000) ? 1f : -1f;
	const float scale = (cast(float)((cast(int)(now % 1_000)) - 500) / 500f) * direction;
	
	//as you can see from this, rendering draws over whatever was drawn before it.
	SDL_SetRenderDrawColour(renderer, 0, 0, 0, 255); //black, full alpha
	SDL_RenderClear(renderer); //start with a blank canvas.
	
	/*
	Just draw the static texture a few times. You can think of it like a
	stamp, there isn't a limit to the number of times you can draw with it.
	*/
	
	//top left
	dstRect.x = (100f * scale);
	dstRect.y = 0f;
	dstRect.w = cast(float)textureWidth;
	dstRect.h = cast(float)textureHeight;
	SDL_RenderTexture(renderer, texture, null, &dstRect);
	
	//centre this one.
	dstRect.x = (cast(float)(windowWidth - textureWidth)) / 2f;
	dstRect.y = (cast(float)(windowHeight - textureHeight)) / 2f;
	dstRect.w = cast(float)textureWidth;
	dstRect.h = cast(float)textureHeight;
	SDL_RenderTexture(renderer, texture, null, &dstRect);
	
	//bottom right.
	dstRect.x = (cast(float)(windowWidth - textureWidth)) - (100f * scale);
	dstRect.y = cast(float)(windowHeight - textureHeight);
	dstRect.w = cast(float)textureWidth;
	dstRect.h = cast(float)textureHeight;
	SDL_RenderTexture(renderer, texture, null, &dstRect);
	
	SDL_RenderPresent(renderer); //put it all on the screen!
	
	return SDL_AppResult.continue_; //carry on with the program!
}

//This function runs once at shutdown.
void SDL_AppQuit(void* appState, SDL_AppResult result){
	SDL_DestroyTexture(texture);
	//SDL will clean up the window/renderer for us.
}
