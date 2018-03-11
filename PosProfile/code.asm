.386
.model	flat,stdcall
option	casemap:none

;###########################################################

Include			windows.inc
Include			kernel32.inc
Includelib	kernel32.lib
Include			user32.inc
Includelib	user32.lib

;###########################################################

.code

_Ascii2Dword16	proto	:DWORD

_UpdateProfile	proc	hWnd
	LOCAL		@stRC:RECT
	LOCAL		@szBuf[260]:BYTE
	LOCAL		@szBuff[260]:BYTE
	pushad
	invoke	GetWindowRect,hWnd,addr @stRC
	mov			eax,@stRC.right
	sub			eax,@stRC.left
	mov			@stRC.right,eax
	mov			eax,@stRC.bottom
	sub			eax,@stRC.top
	mov			@stRC.bottom,eax
	lea			esi,@stRC
	lea			edi,@szBuff
	mov			ecx,4
	@@:
	push		ecx
	cld
	lodsd
	push		0
	push		'X80%'
	mov			ecx,esp
	invoke	wsprintf,edi,ecx,eax
	add			esp,8
	add			edi,eax
	pop			ecx
	loop		@B
	xor			eax,eax
	cld
	stosb
	invoke	GetModuleHandle,0
	mov			ecx,eax
	invoke	GetModuleFileName,ecx,addr @szBuf,sizeof @szBuf
	push		0
	push		'ini.'
	invoke	lstrcat,addr @szBuf,esp
	add			esp,8
	push		'soP'
	mov			esi,esp
	push		'gfC'
	mov			edi,esp
	invoke	WritePrivateProfileString,edi,esi,addr @szBuff,addr @szBuf
	add			esp,8
	popad
	ret
_UpdateProfile	endp

_InitProfile	proc	hWnd
	LOCAL		@szBuf[260]:BYTE
	LOCAL		@stRC:RECT
	LOCAL		@szBuff[260]:BYTE
	pushad
	invoke	GetModuleHandle,0
	mov			ecx,eax
	invoke	GetModuleFileName,ecx,addr @szBuf,sizeof @szBuf
	push		0
	push		'ini.'
	invoke	lstrcat,addr @szBuf,esp
	add			esp,8
	push		0
	mov			esi,esp
	push		'soP'
	mov			ecx,esp
	push		'gfC'
	mov			edi,esp
	invoke	GetPrivateProfileString,edi,ecx,esi,addr @szBuff,sizeof @szBuff,addr @szBuf
	add			esp,12
	.if			eax
		lea			edi,@stRC
		lea			esi,@szBuff
		mov			ecx,4
		@@:
		push		ecx
		invoke	lstrcpyn,addr @szBuf,esi,9
		add			esi,8
		invoke	_Ascii2Dword16,addr @szBuf
		cld
		stosd
		pop			ecx
		loop		@B
		invoke	MoveWindow,hWnd,@stRC.left,@stRC.top,@stRC.right,@stRC.bottom,1
	.endif
	popad
	ret
_InitProfile	endp

End
