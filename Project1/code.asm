.386
.model flat,stdcall
option casemap:none
include windows.inc
include user32.inc
include kernel32.inc
include gdi32.inc
includelib user32.lib
includelib kernel32.lib
includelib gdi32.lib
WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data                     ; initialized data
ClassName db "SimpleWinClass",0        ; the name of our window class
AppName db "Text Editor",0        ; the name of our window
MenuName db "File",0                ; The name of our menu in the resource file.
OpenName db "Open",0
SaveName db "Save",0

open_string db "You're trying to open a file while this fuction is not implemented right now! hhh--",0
save_string db "You're trying to save the file while this fuction is not implemented right now! hhh--",0

curText BYTE "nothing", 1000 DUP(0)
curLen DWORD 7
char WPARAM 20h 

.data?                ; Uninitialized data
hInstance HINSTANCE ?        ; Instance handle of our program
hMenu HMENU ?
hFileMenu HMENU ?
CommandLine LPSTR ?

.const
IDM_OPEN equ 1                    ; Menu IDs
IDM_SAVE equ 2

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

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; fill values in members of wc
    mov   wc.style, CS_HREDRAW or CS_VREDRAW
    mov   wc.lpfnWndProc, OFFSET WndProc
    mov   wc.cbClsExtra,NULL
    mov   wc.cbWndExtra,NULL
    push  hInstance
    pop   wc.hInstance
    mov   wc.hbrBackground,COLOR_WINDOW+1
	mov   wc.lpszMenuName,OFFSET MenuName
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
    mov hFileMenu, eax
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_OPEN, OFFSET OpenName
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveName
    invoke AppendMenu, hMenu, MF_POPUP, hFileMenu, OFFSET MenuName

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
    invoke ShowWindow, hwnd,CmdShow               ; display our window on desktop
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
    .IF uMsg==WM_DESTROY
        invoke PostQuitMessage,NULL

	; �����ж�
	.ELSEIF uMsg==WM_CHAR
        push wParam
        pop char
		mov eax, char
		cmp eax, 8
		je backspace

		mov ebx, OFFSET curText
		add ebx, curLen
		mov [ebx], eax
		inc curLen
		jmp final_pro

		backspace:
		dec curLen
		mov ebx, OFFSET curText
		add ebx, curLen
		mov eax, 0
		mov [ebx], eax
		jmp final_pro

		final_pro:
		invoke InvalidateRect, hWnd,NULL,TRUE

	; ���ڻ���
    .ELSEIF uMsg==WM_PAINT
        invoke BeginPaint,hWnd, ADDR ps
        mov    hdc,eax
        invoke GetClientRect,hWnd, ADDR rect
        invoke DrawText, hdc,ADDR curText,-1, ADDR rect, \
                DT_TOP or DT_LEFT
        invoke EndPaint,hWnd, ADDR ps

	; �˵�����Ӧ
	.ELSEIF uMsg==WM_COMMAND
        mov eax,wParam
        .IF ax==IDM_OPEN
            invoke MessageBox,NULL,ADDR open_string,OFFSET AppName,MB_OK
        .ELSEIF ax==IDM_SAVE
            invoke MessageBox, NULL,ADDR save_string, OFFSET AppName,MB_OK
        .ELSE
            invoke DestroyWindow,hWnd
        .ENDIF

    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor   eax, eax
    ret
WndProc endp

end start