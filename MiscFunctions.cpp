// ModPlug.cpp : Definiert den Einsprungpunkt für die DLL-Anwendung.
//

#include "stdafx.h"

IMPLEMENT_CLASS(AMiscFunctions);

INT numSS = 0;

unsigned char* destbuffer = NULL;

IMPLEMENT_FUNCTION(AMiscFunctions,-1,execScreenshotToTCP);
void 
AMiscFunctions::execScreenshotToTCP(FFrame& Stack, RESULT_DECL)
{
	P_GET_OBJECT(ATcpLink,tc)
	P_FINISH

	HDC screen = GetDC(NULL);
	HDC destDC = CreateCompatibleDC(screen);

	HBITMAP bmp = CreateCompatibleBitmap(screen, 1024, 768);

	SelectObject(destDC, bmp);

	SetStretchBltMode(destDC, HALFTONE);
	
	if(!StretchBlt(destDC, 
		0,0, 
		1024, 768,
		screen, 
		0,0,
		GetSystemMetrics(SM_CXSCREEN),
		GetSystemMetrics(SM_CYSCREEN),
		SRCCOPY)) {
		GLog->Logf(TEXT("Unable to StretchBlt."));
	}

	if (destbuffer == NULL)
		destbuffer = (unsigned char*) malloc(1024*1024*1024);

	unsigned long destsize;
	fnsaveasjpeg(destDC, bmp, &destbuffer, &destsize);

	GLog->Logf(TEXT("Sending image through socket %d"), tc->Socket);
	char messagetype=0;
	send(tc->Socket, &messagetype, 1, 0);
	send(tc->Socket, (const char*)&destsize, sizeof(destsize), 0);
	send(tc->Socket, (const char*) destbuffer, destsize, 0);
	//FILE* f = fopen(fn, "wb+");
	//fwrite(destbuffer, 1, destsize, f);
	//fclose(f);
}


