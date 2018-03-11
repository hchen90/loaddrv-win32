;@\masm32\bin\ml /c /coff /nologo test.bat
;@\masm32\bin\link /subsystem:windows /nologo test.obj
;@pause
;@exit


.386
.model	flat,stdcall
option	casemap:none

;################################################

Include			windows.inc
Include			kernel32.inc
Includelib	kernel32.lib
Include			user32.inc
Includelib	user32.lib
Include			shell32.inc
Includelib	shell32.lib
Include			gdi32.inc
Includelib	gdi32.lib

Includelib	PosProfile.lib

;################################################

.data

APP_INST			STRUCT
	hInstance			dd	? ;;
	hWinMain			dd	? ;;
	hMenu					dd	? ;;
	hIcon					dd	? ;;
	hFont					dd	? ;;
APP_INST			ENDS

APPOBJ				STRUCT
	stInst			APP_INST	<>
APPOBJ				ENDS

szWndClass			db	'AppWnd',0

stApp					APPOBJ	<>


;################################################

_WndProc				proto	:DWORD,:DWORD,:DWORD,:DWORD

_UpdateProfile	proto	:DWORD
_InitProfile		proto	:DWORD

.code
Main:
	pushad
	invoke	GetModuleHandle,0
	mov			stApp.stInst.hInstance,eax
	invoke	LoadIcon,0,IDI_APPLICATION
	mov			stApp.stInst.hIcon,eax
	mov			stApp.stInst.hMenu,0
	sub			esp,sizeof	WNDCLASSEX
	mov			esi,esp
	mov			edi,esp
	xor			eax,eax
	mov			ecx,sizeof	WNDCLASSEX
	cld
	rep			stosb
	assume	esi:PTR WNDCLASSEX
	mov			[esi].cbSize,sizeof WNDCLASSEX
	mov			[esi].style,CS_VREDRAW or CS_HREDRAW
	mov			[esi].lpfnWndProc,offset _WndProc
	push		stApp.stInst.hInstance
	pop			[esi].hInstance
	mov			eax,stApp.stInst.hIcon
	mov			[esi].hIcon,eax
	mov			[esi].hIconSm,eax
	invoke	LoadCursor,0,IDC_ARROW
	mov			[esi].hCursor,eax
	mov			[esi].hbrBackground,COLOR_BTNFACE+1
	mov			[esi].lpszClassName,offset szWndClass
	invoke	RegisterClassEx,esi
	or			eax,eax
	jz			@F
	invoke	CreateWindowEx,0,offset szWndClass,offset szWndClass,WS_OVERLAPPEDWINDOW,\
					CW_USEDEFAULT,CW_USEDEFAULT,700,600,\
					0,stApp.stInst.hMenu,stApp.stInst.hInstance,0
	or			eax,eax
	jz			@F
	invoke	ShowWindow,stApp.stInst.hWinMain,SW_SHOW
	invoke	UpdateWindow,stApp.stInst.hWinMain
	___MsgLoop:
	invoke	GetMessage,esi,0,0,0
	or			eax,eax
	jz			@F
	invoke	TranslateMessage,esi
	invoke	DispatchMessage,esi
	jmp		___MsgLoop
	@@:
	assume	esi:nothing
	add		esp,sizeof	WNDCLASSEX
	popad
	invoke	ExitProcess,0

_WndProc	proc	uses esi edi ebx,hWnd,uMsg,wParam,lParam
	.if		uMsg == WM_CREATE
		push		hWnd
		pop			stApp.stInst.hWinMain
		invoke	_InitProfile,hWnd
	.elseif	uMsg == WM_CLOSE
		___wndClose:
		invoke	_UpdateProfile,hWnd
		invoke	DestroyWindow,hWnd
		invoke	PostQuitMessage,0
	.else
		invoke	DefWindowProc,hWnd,uMsg,wParam,lParam
		ret
	.endif
	xor			eax,eax
	ret
_WndProc	endp

End	Main
