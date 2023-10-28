.386
.model flat,stdcall
option casemap:none
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
include comdlg32.inc
include shlwapi.inc

includelib user32.lib
includelib kernel32.lib
includelib comdlg32.lib
includelib gdi32.lib
includelib shlwapi.lib
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data                     ; initialized data
ClassName db "SimpleWinClass",0        ; the name of our window class
AppName db "Text Editor",0        ; the name of our window

FileName db "File",0                ; The name of our menu in the resource file.
OpenName db "Open",0
SaveName db "Save",0

EditName db "Edit",0
DateName db "Date",0

ViewName db "View",0
FontName db "Font",0
SizeName db "Size",0

szFileName	db	MAX_PATH dup (0)
pBuffer db 4096 dup(0)

EditClassName db "EDIT"
clientWidth DWORD 0
clientHeight DWORD 0

open_string db "You're trying to open a file while this fuction is not implemented right now! hhh--",0
save_string db "You're trying to save the file while this fuction is not implemented right now! hhh--",0

curText BYTE "nothing", 1000 DUP(0)
curLen DWORD 7
char WPARAM 20h 

.data?                ; Uninitialized data
hInstance HINSTANCE ?        ; Instance handle of our program
hMenu HMENU ?
hFileMenu HMENU ?
hEditMenu HMENU ?
hViewMenu HMENU ?
CommandLine LPSTR ?

.const
IDM_OPEN equ 1                    ; Menu IDs
IDM_SAVE equ 2
IDM_DATE equ 3
IDM_FONT equ 4
IDM_SIZE equ 5

szWarnCaption	db	'����',0
szCreateWarnMessage	db	'CreateFile����',0
szReadWarnMessage	db	'ReadFile����',0
szFilter	db	'Text Files(*.txt)',0,'*.txt',0,'All Files(*.*)',0,'*.*',0,0
szDefExt	db	'txt',0

.code                ; Here begins our code
start:
invoke GetModuleHandle, NULL            ; get the instance handle of our program.
                                                                       ; Under Win32, hmodule==hinstance mov hInstance,eax
mov hInstance,eax
invoke GetCommandLine                        ; get the command line. You don't have to call this function IF
                                                                       ; your program doesn't process the command line.
mov CommandLine,eax
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; call the main function
invoke ExitProcess, eax                           ; quit our program. The exit code is returned in eax from WinMain.


WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX                                            ; create local variables on stack
    LOCAL msg:MSG
    LOCAL hwnd:HWND
	LOCAL hEdit:HWND
	LOCAL rect:RECT

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; fill values in members of wc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_WINDOW+1
	mov   wc.lpszMenuName,OFFSET FileName
    mov   wc.lpszClassName,OFFSET ClassName
    invoke LoadIcon,NULL,IDI_APPLICATION
    mov   wc.hIcon,eax
    mov   wc.hIconSm,eax
    invoke LoadCursor,NULL,IDC_ARROW
    mov   wc.hCursor,eax

	;�˵���
	invoke CreateMenu
    mov hMenu, eax
	invoke CreatePopupMenu

    mov hFileMenu, eax ; �ļ��˵�
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_OPEN, OFFSET OpenName
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveName
	invoke AppendMenu, hMenu, MF_POPUP, hFileMenu, OFFSET FileName

	invoke CreatePopupMenu
    mov hEditMenu, eax ; �༭�˵�
    invoke AppendMenu, hEditMenu, MF_STRING, IDM_OPEN, OFFSET DateName
    invoke AppendMenu, hMenu, MF_POPUP, hEditMenu, OFFSET EditName

	mov hViewMenu, eax ; ��ͼ�˵�
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_OPEN, OFFSET OpenName
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveName
    invoke AppendMenu, hMenu, MF_POPUP, hViewMenu, OFFSET ViewName

    invoke RegisterClassEx, addr wc                       ; register our window class
    invoke CreateWindowEx,NULL,\
                ADDR ClassName,\
                ADDR AppName,\
                WS_OVERLAPPEDWINDOW,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                CW_USEDEFAULT,\
                NULL,\
                hMenu,\
                hInst,\
                NULL
    mov   hwnd,eax
	invoke SetMenu, hwnd, hMenu
	
	; ����edit�ؼ�
	invoke GetClientRect, hwnd, ADDR rect
	push rect.bottom
	pop clientHeight
	push rect.right
	pop clientWidth
	invoke CreateWindowEx, NULL,\
				ADDR EditName, \
				NULL, \
				WS_CHILD or WS_VISIBLE or WS_VSCROLL or ES_LEFT or ES_MULTILINE or ES_AUTOVSCROLL, \
				0, 0, \
				clientWidth, clientHeight, \
				hwnd, 
				NULL, 
				hInstance, 
				NULL
	mov hEdit, eax

    invoke ShowWindow, hwnd, CmdShow               ; display our window on desktop
	; invoke ShowWindow, hEdit, CmdShow
    invoke UpdateWindow, hwnd                                 ; refresh the client area

    .WHILE TRUE                                                         ; Enter message loop
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam                                            ; return exit code in eax
    ret
WinMain endp

WndProc proc hWnd:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
    LOCAL hdc:HDC
    LOCAL ps:PAINTSTRUCT
    LOCAL rect:RECT
	LOCAL bytesRead:DWORD
	LOCAL hFile:HANDLE
	LOCAL dwBytesWritten:DWORD
	LOCAL ofn:OPENFILENAME

    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL

	; �˵�����Ӧ
	.ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .IF ax==IDM_OPEN
			invoke	RtlZeroMemory, addr ofn, sizeof ofn
			mov	ofn.lStructSize,sizeof ofn
			push	hWnd
			pop	ofn.hwndOwner
			mov	ofn.lpstrFilter, offset szFilter
			mov	ofn.lpstrFile, offset szFileName
			mov	ofn.nMaxFile, MAX_PATH
			mov	ofn.Flags, OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST
			invoke	GetOpenFileName, addr ofn
			.if	eax
				mov eax, ofn.lpstrFile
					mov esi, eax
					xor ecx, ecx
				.while byte ptr [esi] != 0 ;Get the name of file to be open
					mov al, byte ptr [esi]
					mov byte ptr [szFileName + ecx], al
					inc esi
					inc ecx
				.endw

				; Try to open file
				invoke CreateFile, addr szFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				mov hFile, eax

				.if hFile != INVALID_HANDLE_VALUE
					invoke ReadFile, hFile, addr pBuffer, 4096, addr bytesRead, NULL
					.if eax != 0 
						mov ecx, bytesRead
						mov curLen, ecx
						mov	esi, 0;
			CopyLoop:	mov al, byte ptr [pBuffer + esi]
						mov	byte ptr [curText + esi], al
						inc esi
						loop CopyLoop
					.else
						 invoke MessageBox, 0, addr szReadWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
					.endif
					invoke CloseHandle, hFile
					invoke InvalidateRect, hWnd,NULL,TRUE
				  .else
						invoke MessageBox, 0, addr szCreateWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
				  .endif
			.endif
        .ELSEIF ax==IDM_SAVE
			invoke	RtlZeroMemory, addr ofn, sizeof ofn
			mov	ofn.lStructSize,sizeof ofn
			push	hWnd
			pop	ofn.hwndOwner
			mov	ofn.lpstrFilter, offset szFilter
			mov	ofn.lpstrFile, offset szFileName
			mov ofn.lpstrDefExt, offset szDefExt
			mov	ofn.nMaxFile, MAX_PATH
			mov ofn.Flags, OFN_OVERWRITEPROMPT
			invoke	GetSaveFileName, addr ofn
			.if	eax
				mov eax, ofn.lpstrFile
					mov esi, eax
					xor ecx, ecx
				.while byte ptr [esi] != 0 ;Get the name of file to be open
					mov al, byte ptr [esi]
					mov byte ptr [szFileName + ecx], al
					inc esi
					inc ecx
				.endw
				; Try to open file
				invoke CreateFile, addr szFileName, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
				mov hFile, eax
				.if hFile != INVALID_HANDLE_VALUE
					mov edx, offset curText
					mov ecx, curLen
					invoke WriteFile, hFile, edx, ecx, addr dwBytesWritten, 0
					invoke CloseHandle, hFile
				.else
					invoke MessageBox, 0, addr szCreateWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
				.endif
			.endif
        .ENDIF
    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor   eax, eax
    ret
WndProc endp

end start