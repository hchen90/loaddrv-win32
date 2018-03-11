.386
.model	flat,stdcall
option	casemap:none

;###########################################################

Include			windows.inc
Include			kernel32.inc
Includelib	kernel32.lib
Include			user32.inc
Includelib	user32.lib
Include			shell32.inc
Includelib	shell32.lib
Include			comdlg32.inc
Includelib	comdlg32.lib
Include			advapi32.inc
Includelib	advapi32.lib

Includelib	PosProfile.lib

;###########################################################

.data
hInstance			dd	?
hWinMain			dd	?
hIcon					dd	?
hMenu					dd	?
hScm					dd	?
hService			dd	?

szAbout				db	'About ..#'
szTitle				db	'LoadDriver',0
szAboutX			db	'Copyright(C)2013 chenxiang',0
szOfDlgTitle	db	'Open a Driver ...',0
szFilter			db	'Driver(*.sys)',0,'*.sys',0,'All Files(*.*)',0,'*.*',0,0

szTxt_00			db	'this driver is ready ...',0
szTxt_01			db	'_driver',0
szTxt_02			db	'Win32 Own Process',0
szTxt_03			db	'Win32 Share Process',0
szTxt_04			db	'Kernel Driver',0
szTxt_05			db	'File System Driver',0
szTxt_06			db	'Interactive Process',0
szTxt_07			db	'Boot Start',0
szTxt_08			db	'System Start',0
szTxt_09			db	'Auto Start',0
szTxt_10			db	'Demand Start',0
szTxt_11			db	'Disabled',0
szTxt_12			db	'Ignore',0
szTxt_13			db	'Normal',0
szTxt_14			db	'Severe',0
szTxt_15			db	'Critical',0
szTxt_16			db	'ServiceType',0
szTxt_17			db	'CurState',0
szTxt_18			db	'ControlsAccepted',0
szTxt_19			db	'Win32ExitCode',0
szTxt_20			db	'DisplayName',0
szTxt_21			db	'ServiceName',0
szTxt_22			db	'%lu',0
szTxt_23			db	'SpecificExitCode',0
szTxt_24			db	'Stopped',0
szTxt_25			db	'Start Pending',0
szTxt_26			db	'Stop Pending',0
szTxt_27			db	'Running',0
szTxt_28			db	'Continue Pending',0
szTxt_29			db	'Pause Pending',0
szTxt_30			db	'Paused',0
szTxt_31			db	'???',0
szTxt_32			db	'Win32 Own Process',0
szTxt_33			db	'Win32 Share Process',0
szTxt_34			db	'Kernel Driver',0
szTxt_35			db	'File System Driver',0
szTxt_36			db	'Interactive Process',0
szTxt_37			db	'[Stop] ',0
szTxt_38			db	'[Pause Continue] ',0
szTxt_39			db	'[Shutdown]',0
szTxt_40			db	'Error Code:%08X ;Error :%s .',0
szTxt_41			db	'service control manager opened successful .',0
szTxt_42			db	'service opened successful .',0
szTxt_43			db	'service created successful .',0
szTxt_44			db	'A Current Service is Opened.',0AH,'Delete it ?',0
szTxt_45			db	'Question?',0
szTxt_46			db	'delete service successful .',0
szTxt_47			db	'delete service control manager successful .',0
szTxt_48			db	'stop service successful .',0
szTxt_49			db	'start service successful .',0

;###########################################################

.code
_InitProfile		proto	:DWORD
_UpdateProfile	proto	:DWORD
_AddText				proto	:DWORD
_ErrorReport		proto	:DWORD

ZEROMEM			MACRO	_lpMem,_cbSize
	pushad
	mov			edi,_lpMem
	xor			eax,eax
	mov			ecx,_cbSize
	cld
	rep			stosb
	popad
ENDM

TICKDOT			MACRO	_lpMem
	pushad
	mov			esi,_lpMem
	@@@THICKDOT_1:
	xor			eax,eax
	cld
	lodsb
	or			eax,eax
	jz			@@@THICKDOT_2
	cmp			eax,'.'
	jnz			@@@THICKDOT_1
	dec			esi
	mov			BYTE PTR [esi],0
	@@@THICKDOT_2:
	popad
ENDM

_CloseService	proc
	LOCAL		@szBuf[260]:BYTE
	LOCAL		@stSS:SERVICE_STATUS
	pushad
	.if			hService
		invoke	ControlService,hService,SERVICE_CONTROL_STOP,addr @stSS
		invoke	DeleteService,hService
		.if			!eax
			invoke	_ErrorReport,addr @szBuf
			invoke	_AddText,addr @szBuf
		.else
			invoke	CloseServiceHandle,hService
			.if			!eax
				invoke	_ErrorReport,addr @szBuf
				invoke	_AddText,addr @szBuf
			.else
				invoke	_AddText,offset szTxt_46
				mov			hService,0
			.endif
		.endif
	.endif
	popad
	ret
_CloseService	endp

_CloseSCM		proc
	LOCAL		@szBuf[260]:BYTE
	pushad
	.if			hScm
		invoke	CloseServiceHandle,hScm
		.if			!eax
			invoke	_ErrorReport,addr @szBuf
			invoke	_AddText,addr @szBuf
		.else
			invoke	_AddText,offset szTxt_47
			mov			hScm,0
		.endif
	.endif
	popad
	ret
_CloseSCM		endp

_CleanAll		proc
	invoke	_CloseService
	invoke	_CloseSCM
	ret
_CleanAll		endp

_ErrorReport	proc	_lpBuf
		LOCAL		@szBuf[260]:BYTE
		pushad
		call		GetLastError
		push		eax
		lea			ecx,@szBuf
		invoke	FormatMessage,FORMAT_MESSAGE_IGNORE_INSERTS or FORMAT_MESSAGE_FROM_SYSTEM,\
						0,eax,0,ecx,sizeof @szBuf,0
		pop			eax
		lea			ecx,@szBuf
		invoke	wsprintf,_lpBuf,offset szTxt_40,eax,ecx
		invoke	MessageBeep,30H
		popad
		ret
_ErrorReport	endp

_AddText	proc	_lpTxt
	pushad
	invoke	SendDlgItemMessage,hWinMain,1015,LB_ADDSTRING,0,_lpTxt
	popad
	ret
_AddText	endp

_InsertItem	proc	_hList,_lpText,_iItem,_iSub
	LOCAL		@stLi:LV_ITEM
	pushad
	lea			eax,@stLi
	ZEROMEM	eax,sizeof @stLi
	mov			@stLi.imask,LVIF_TEXT
	push		_iItem
	pop			@stLi.iItem
	push		_iSub
	pop			@stLi.iSubItem
	push		_lpText
	pop			@stLi.pszText
	.if			@stLi.iSubItem
		invoke	SendMessage,_hList,LVM_SETITEM,0,addr @stLi
	.else
		invoke	SendMessage,_hList,LVM_INSERTITEM,0,addr @stLi
	.endif
	popad
	ret
_InsertItem	endp

_InsertHdr	proc	_hList,_lpText,_lx
	LOCAL		@stLc:LV_COLUMN
	pushad
	lea			eax,@stLc
	ZEROMEM	eax,sizeof @stLc
	mov			@stLc.imask,LVCF_TEXT or LVCF_WIDTH or LVCF_FMT
	mov			@stLc.fmt,LVCFMT_CENTER
	push		_lx
	pop			@stLc.lx
	push		_lpText
	pop			@stLc.pszText
	invoke	SendMessage,_hList,LVM_INSERTCOLUMN,0,addr @stLc
	popad
	ret
_InsertHdr	endp

_EnumAllServices	proc	_hList
	LOCAL		@hScm:DWORD
	LOCAL		@lpESS:DWORD
	LOCAL		@hNext:DWORD
	LOCAL		@dwNeeded:DWORD
	LOCAL		@dwReted:DWORD
	LOCAL		@nSize:DWORD
	LOCAL		@szBuf[260]:BYTE
	pushad
	invoke	_InsertHdr,_hList,offset szTxt_18,100
	invoke	_InsertHdr,_hList,offset szTxt_23,80
	invoke	_InsertHdr,_hList,offset szTxt_19,60
	invoke	_InsertHdr,_hList,offset szTxt_16,90
	invoke	_InsertHdr,_hList,offset szTxt_17,60
	invoke	_InsertHdr,_hList,offset szTxt_20,120
	invoke	_InsertHdr,_hList,offset szTxt_21,100
	mov			@hNext,0
	mov			@dwNeeded,0
	mov			@dwReted,0
	mov			@lpESS,0
	mov			@nSize,4
	invoke	OpenSCManager,0,0,SC_MANAGER_ENUMERATE_SERVICE
	.if			eax
		mov			@hScm,eax
		@@:
		invoke	EnumServicesStatus,@hScm,SERVICE_WIN32 or SERVICE_DRIVER,SERVICE_ACTIVE or SERVICE_INACTIVE,@lpESS,@nSize,addr @dwNeeded,addr @dwReted,addr @hNext
		.if			eax
			mov			esi,@lpESS
			mov			@nSize,0
			@@@LOP0:
			invoke	_InsertItem,_hList,(ENUM_SERVICE_STATUS ptr [esi]).lpServiceName,@nSize,0
			invoke	_InsertItem,_hList,(ENUM_SERVICE_STATUS ptr [esi]).lpDisplayName,@nSize,1
			mov			eax,(ENUM_SERVICE_STATUS ptr [esi]).ServiceStatus.dwCurrentState
			.if			eax == SERVICE_STOPPED
				lea			eax,szTxt_24
			.elseif eax == SERVICE_START_PENDING
				lea			eax,szTxt_25
			.elseif eax == SERVICE_STOP_PENDING
				lea			eax,szTxt_26
			.elseif eax == SERVICE_RUNNING
				lea			eax,szTxt_27
			.elseif eax == SERVICE_CONTINUE_PENDING
				lea			eax,szTxt_28
			.elseif eax == SERVICE_PAUSE_PENDING
				lea			eax,szTxt_29
			.elseif eax == SERVICE_PAUSED
				lea			eax,szTxt_30
			.else
				lea			eax,szTxt_31
			.endif
			invoke	_InsertItem,_hList,eax,@nSize,2
			mov			eax,(ENUM_SERVICE_STATUS ptr [esi]).ServiceStatus.dwServiceType
			.if			eax == SERVICE_WIN32_OWN_PROCESS
				lea			eax,szTxt_32
			.elseif eax == SERVICE_WIN32_SHARE_PROCESS
				lea			eax,szTxt_33
			.elseif eax == SERVICE_KERNEL_DRIVER
				lea			eax,szTxt_34
			.elseif eax == SERVICE_FILE_SYSTEM_DRIVER
				lea			eax,szTxt_35
			.elseif eax == SERVICE_INTERACTIVE_PROCESS
				lea			eax,szTxt_36
			.else
				lea			eax,szTxt_31
			.endif
			invoke	_InsertItem,_hList,eax,@nSize,3
			invoke	wsprintf,addr @szBuf,offset szTxt_22,(ENUM_SERVICE_STATUS ptr [esi]).ServiceStatus.dwWin32ExitCode
			invoke	_InsertItem,_hList,addr @szBuf,@nSize,4
			invoke	wsprintf,addr @szBuf,offset szTxt_22,(ENUM_SERVICE_STATUS ptr [esi]).ServiceStatus.dwServiceSpecificExitCode
			invoke	_InsertItem,_hList,addr @szBuf,@nSize,5
			lea			eax,@szBuf
			mov			DWORD PTR [eax],0
			mov			ebx,(ENUM_SERVICE_STATUS ptr [esi]).ServiceStatus.dwControlsAccepted
			.if			ebx & SERVICE_ACCEPT_STOP
				invoke	lstrcpy,addr @szBuf,offset szTxt_37
			.endif
			.if			ebx & SERVICE_ACCEPT_PAUSE_CONTINUE
				invoke	lstrcat,addr @szBuf,offset szTxt_38
			.endif
			.if			ebx & SERVICE_ACCEPT_SHUTDOWN
				invoke	lstrcat,addr @szBuf,offset szTxt_39
			.endif
			invoke	_InsertItem,_hList,addr @szBuf,@nSize,6
			inc			@nSize
			add			esi,sizeof ENUM_SERVICE_STATUS
			dec			@dwReted
			cmp			@dwReted,0
			jg			@@@LOP0
		.else
			invoke	GetLastError
			.if			eax == ERROR_MORE_DATA
				invoke	GlobalAlloc,GPTR,@dwNeeded
				mov			@lpESS,eax
				push		@dwNeeded
				pop			@nSize
				jmp			@B
			.endif
		.endif
		invoke	CloseServiceHandle,@hScm
	.endif
	.if			@lpESS
		invoke	GlobalFree,@lpESS
	.endif
	popad
	ret
_EnumAllServices	endp

_EnumDlgProc	proc	uses esi edi ebx,hWnd,uMsg,wParam,lParam
		LOCAL		@stRc:RECT
	.if			uMsg == WM_INITDIALOG
		invoke	SendMessage,hWnd,WM_SETTEXT,0,offset szTitle
		invoke	GetWindowRect,lParam,addr @stRc
		.if			!eax
			and			@stRc.left,0
			and			@stRc.top,0
			mov			@stRc.right,500
			mov			@stRc.bottom,400
		.else
			mov			eax,@stRc.left
			sub			@stRc.right,eax
			mov			eax,@stRc.top
			sub			@stRc.bottom,eax
		.endif
		invoke	SetWindowPos,hWnd,HWND_TOPMOST,@stRc.left,@stRc.top,@stRc.right,@stRc.bottom,SWP_SHOWWINDOW
		invoke	GetClientRect,hWnd,addr @stRc
		.if			eax
			invoke	GetDlgItem,hWnd,1
			.if			eax
				push		eax
				push		0
				invoke	CreateThread,0,0,offset _EnumAllServices,eax,0,esp
				add			esp,4
				invoke	CloseHandle,eax
				pop			eax
				invoke	SetWindowPos,eax,HWND_TOP,@stRc.left,@stRc.top,@stRc.right,@stRc.bottom,SWP_SHOWWINDOW
			.endif
		.endif
		invoke	SendDlgItemMessage,hWnd,1,LVM_SETEXTENDEDLISTVIEWSTYLE,0,LVS_EX_FULLROWSELECT or LVS_EX_HEADERDRAGDROP
		invoke	_InitProfile,hWnd
	.elseif uMsg == WM_SIZE
		invoke	GetDlgItem,hWnd,1
		mov			edi,eax
		invoke	GetClientRect,hWnd,addr @stRc
		.if			eax && edi
			invoke	SetWindowPos,edi,HWND_TOP,@stRc.left,@stRc.top,@stRc.right,@stRc.bottom,SWP_SHOWWINDOW
		.endif
	.elseif uMsg == WM_CLOSE
		invoke	_UpdateProfile,hWnd
		invoke	EndDialog,hWnd,0
	.else
		xor			eax,eax
		ret
	.endif
	or			eax,1
	ret
_EnumDlgProc	endp

_DlgProc	proc	uses esi edi ebx,hWnd,uMsg,wParam,lParam
		LOCAL		@stOf:OPENFILENAME
		LOCAL		@szBuf[260]:BYTE
		LOCAL		@szRef[260]:BYTE
		LOCAL		@stSS:SERVICE_STATUS
	.if			uMsg == WM_INITDIALOG
		push		hWnd
		pop			hWinMain
		invoke	SendMessage,hWnd,WM_SETTEXT,0,offset szTitle
		invoke	LoadIcon,hInstance,100
		.if			eax
			mov			hIcon,eax
			invoke	SendMessage,hWnd,WM_SETICON,ICON_SMALL,eax
		.endif
		invoke	LoadMenu,hInstance,100
		.if			eax
			mov			hMenu,eax
			invoke	SetMenu,hWnd,eax
		.endif
		;;
		invoke	SendDlgItemMessage,hWnd,1007,CB_ADDSTRING,0,offset szTxt_02
		invoke	SendDlgItemMessage,hWnd,1007,CB_ADDSTRING,0,offset szTxt_03
		invoke	SendDlgItemMessage,hWnd,1007,CB_ADDSTRING,0,offset szTxt_04
		invoke	SendDlgItemMessage,hWnd,1007,CB_ADDSTRING,0,offset szTxt_05
		invoke	SendDlgItemMessage,hWnd,1007,CB_ADDSTRING,0,offset szTxt_06
		invoke	SendDlgItemMessage,hWnd,1007,CB_SETCURSEL,2,0
		;;
		invoke	SendDlgItemMessage,hWnd,1008,CB_ADDSTRING,0,offset szTxt_07
		invoke	SendDlgItemMessage,hWnd,1008,CB_ADDSTRING,0,offset szTxt_08
		invoke	SendDlgItemMessage,hWnd,1008,CB_ADDSTRING,0,offset szTxt_09
		invoke	SendDlgItemMessage,hWnd,1008,CB_ADDSTRING,0,offset szTxt_10
		invoke	SendDlgItemMessage,hWnd,1008,CB_ADDSTRING,0,offset szTxt_11
		invoke	SendDlgItemMessage,hWnd,1008,CB_SETCURSEL,3,0
		;;
		invoke	SendDlgItemMessage,hWnd,1009,CB_ADDSTRING,0,offset szTxt_12
		invoke	SendDlgItemMessage,hWnd,1009,CB_ADDSTRING,0,offset szTxt_13
		invoke	SendDlgItemMessage,hWnd,1009,CB_ADDSTRING,0,offset szTxt_14
		invoke	SendDlgItemMessage,hWnd,1009,CB_ADDSTRING,0,offset szTxt_15
		invoke	SendDlgItemMessage,hWnd,1009,CB_SETCURSEL,0,0
	.elseif uMsg == WM_COMMAND
		mov			eax,wParam
		and			eax,0FFFFH
		.if			eax == 1017	;;	about
			invoke	ShellAbout,hWnd,offset szAbout,offset szAboutX,hIcon
		.elseif eax == 1018	;;	Enum Ser
			invoke	DialogBoxParam,hInstance,101,hWnd,offset _EnumDlgProc,hWnd
		.elseif eax == 1019
			invoke	_CleanAll
		.elseif eax == 1000	;;	Open
			lea			eax,@stOf
			ZEROMEM	eax,sizeof @stOf
			lea			eax,@szBuf
			ZEROMEM	eax,sizeof @szBuf
			lea			eax,@szRef
			ZEROMEM	eax,sizeof @szRef
			mov			@stOf.lStructSize,sizeof @stOf
			push		hWnd
			pop			@stOf.hwndOwner
			push		hInstance
			pop			@stOf.hInstance
			mov			@stOf.lpstrFilter,offset szFilter
			lea			eax,@szBuf
			mov			@stOf.lpstrFile,eax
			mov			@stOf.nMaxFile,sizeof @szBuf
			lea			eax,@szRef
			mov			@stOf.lpstrFileTitle,eax
			mov			@stOf.nMaxFileTitle,sizeof @szRef
			mov			@stOf.lpstrTitle,offset szOfDlgTitle
			mov			@stOf.Flags,OFN_EXPLORER
			invoke	GetOpenFileName,addr @stOf
			.if			eax
				invoke	SendDlgItemMessage,hWnd,1001,WM_SETTEXT,0,addr @szBuf
				lea			eax,@szRef
				TICKDOT	eax
				invoke	SendDlgItemMessage,hWnd,1002,WM_SETTEXT,0,addr @szRef
				invoke	lstrcat,addr @szRef,offset szTxt_01
				invoke	SendDlgItemMessage,hWnd,1003,WM_SETTEXT,0,addr @szRef
				invoke	_AddText,offset szTxt_00
				invoke	_AddText,addr @szBuf
			.endif
		.elseif eax == 1011	;;	Start
			.if				hService
				invoke	StartService,hService,0,0
				.if			eax
					invoke	_AddText,offset szTxt_49
				.else
					invoke	_ErrorReport,addr @szBuf
					invoke	_AddText,addr @szBuf
				.endif
			.else
				invoke	_ErrorReport,addr @szBuf
				invoke	_AddText,addr @szBuf
			.endif
		.elseif eax == 1012	;;	Install
			invoke	SendDlgItemMessage,hWnd,1001,WM_GETTEXT,sizeof @szBuf,addr @szBuf
			.if			eax
				sub			esp,260
				mov			esi,esp
				sub			esp,260
				mov			edi,esp
				ZEROMEM	esi,260
				ZEROMEM	edi,260
				invoke	SendDlgItemMessage,hWnd,1004,WM_GETTEXT,260,esi
				invoke	SendDlgItemMessage,hWnd,1005,WM_GETTEXT,260,edi
				mov			al,BYTE PTR [esi]
				mov			cl,BYTE PTR [edi]
				and			eax,0FFH
				and			ecx,0FFH
				.if			eax
					mov			eax,esi
				.else
					xor			eax,eax
				.endif
				.if			ecx
					mov			ecx,edi
				.else
					xor			ecx,ecx
				.endif
				invoke	OpenSCManager,eax,ecx,SC_MANAGER_ALL_ACCESS
				.if			eax
					mov			hScm,eax
					invoke	_AddText,offset szTxt_41
					invoke	SendDlgItemMessage,hWnd,1002,WM_GETTEXT,260,esi
					invoke	SendDlgItemMessage,hWnd,1003,WM_GETTEXT,260,edi
					invoke	SendDlgItemMessage,hWnd,1007,CB_GETCURSEL,0,0
					.if			!eax
						mov			eax,SERVICE_WIN32_OWN_PROCESS
					.elseif eax == 1
						mov			eax,SERVICE_WIN32_SHARE_PROCESS
					.elseif eax == 3
						mov			eax,SERVICE_FILE_SYSTEM_DRIVER
					.elseif	eax == 4
						mov			eax,SERVICE_INTERACTIVE_PROCESS
					.else
						mov			eax,SERVICE_KERNEL_DRIVER
					.endif
					push		eax
					invoke	SendDlgItemMessage,hWnd,1008,CB_GETCURSEL,0,0
					.if			!eax
						mov			ecx,SERVICE_BOOT_START
					.elseif eax == 1
						mov			ecx,SERVICE_SYSTEM_START
					.elseif eax == 2
						mov			ecx,SERVICE_AUTO_START
					.elseif eax == 4
						mov			ecx,SERVICE_DISABLED
					.else
						mov			ecx,SERVICE_DEMAND_START
					.endif
					push		ecx
					invoke	SendDlgItemMessage,hWnd,1009,CB_GETCURSEL,0,0
					.if			eax == 1
						mov			edx,SERVICE_ERROR_NORMAL
					.elseif eax == 2
						mov			edx,SERVICE_ERROR_SEVERE
					.elseif eax == 3
						mov			edx,SERVICE_ERROR_CRITICAL
					.else
						mov			edx,SERVICE_ERROR_IGNORE
					.endif
					pop			ecx
					pop			eax
					mov			ebx,eax
					invoke	CreateService,hScm,esi,edi,SERVICE_ALL_ACCESS,ebx,ecx,edx,addr @szBuf,0,0,0,0,0
					.if			eax
						mov			hService,eax
						invoke	_AddText,offset szTxt_43
					.else
						invoke	_ErrorReport,addr @szBuf
						invoke	_AddText,addr @szBuf
					.endif
				.else
					invoke	_ErrorReport,addr @szBuf
					invoke	_AddText,addr @szBuf
				.endif
				add			esp,520
			.else
				sub			esp,260
				mov			esi,esp
				sub			esp,260
				mov			edi,esp
				ZEROMEM	esi,260
				ZEROMEM	edi,260
				invoke	SendDlgItemMessage,hWnd,1004,WM_GETTEXT,260,esi
				invoke	SendDlgItemMessage,hWnd,1005,WM_GETTEXT,260,edi
				mov			al,BYTE PTR [esi]
				mov			cl,BYTE PTR [edi]
				and			eax,0FFH
				and			ecx,0FFH
				.if			eax
					mov			eax,esi
				.else
					xor			eax,eax
				.endif
				.if			ecx
					mov			ecx,edi
				.else
					xor			ecx,ecx
				.endif
				invoke	OpenSCManager,eax,ecx,SC_MANAGER_ALL_ACCESS
				.if			eax
					mov			hScm,eax
					invoke	_AddText,offset szTxt_41
					invoke	SendDlgItemMessage,hWnd,1002,WM_GETTEXT,260,esi
					invoke	OpenService,hScm,esi,SERVICE_ALL_ACCESS
					.if			eax
						mov			hService,eax
						invoke	_AddText,offset szTxt_42
					.else
						invoke	_ErrorReport,addr @szBuf
						invoke	_AddText,addr @szBuf
					.endif
				.else
					invoke	_ErrorReport,addr @szBuf
					invoke	_AddText,addr @szBuf
				.endif
				add			esp,520
			.endif
		.elseif eax == 1013	;;	Stop
			lea			eax,@stSS
			ZEROMEM	eax,sizeof @stSS
			invoke	ControlService,hService,SERVICE_CONTROL_STOP,addr @stSS
			.if			eax
				invoke	_AddText,offset szTxt_48
			.else
				invoke	_ErrorReport,addr @szBuf
				invoke	_AddText,addr @szBuf
			.endif
		.elseif eax == 1014	;;	Delete
			invoke	_CloseService
		.elseif eax == 1016	;;	Exit
			jmp			@F
		.endif
	.elseif uMsg == WM_CLOSE
		@@:
		.if			hScm && hService
			invoke	MessageBox,hWnd,offset szTxt_44,offset szTxt_45,MB_OKCANCEL or MB_ICONQUESTION or MB_DEFBUTTON1
			.if			eax == IDOK
				invoke	_CleanAll
			.endif
		.endif
		invoke	EndDialog,hWnd,0
	.elseif uMsg == WM_LBUTTONDOWN
		invoke	SendMessage,hWnd,WM_NCLBUTTONDOWN,HTCAPTION,0
	.else
		xor			eax,eax
		ret
	.endif
	or			eax,1
	ret
_DlgProc	endp

_Main:
	invoke	GetModuleHandle,0
	.if			eax
		mov			hInstance,eax
		invoke	DialogBoxParam,hInstance,100,0,offset _DlgProc,0
	.endif
	invoke	ExitProcess,0

End _Main
