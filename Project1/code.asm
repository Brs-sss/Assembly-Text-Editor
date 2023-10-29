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

hGlobal    dd 0           ; 全局内存句柄
lpText     dd 0           ; 文本缓冲区指针
strStart   DWORD 0
strEnd     DWORD 0
emptyString db 0

.data?                ; 未初始化变量声明区域
hInstance HINSTANCE ?        ; 程序的实例句柄
hMenu HMENU ?
hFileMenu HMENU ?
hEditMenu HMENU ?
hViewMenu HMENU ?
hEdit HWND ?
CommandLine LPSTR ?

.const
IDM_OPEN equ 1                    ; 菜单ID
IDM_SAVE equ 2
IDM_DATE equ 3
IDM_FONT equ 4
IDM_SIZE equ 5

szWarnCaption	db	'错误',0
szCreateWarnMessage	db	'CreateFile错误',0
szReadWarnMessage	db	'ReadFile错误',0
szFilter	db	'Text Files(*.txt)',0,'*.txt',0,'All Files(*.*)',0,'*.*',0,0
szDefExt	db	'txt',0

.code                ; Here begins our code
start:
invoke GetModuleHandle, NULL            ; 获取程序的实例句柄

mov hInstance,eax
invoke GetCommandLine                        ; 获取命令行参数

mov CommandLine,eax
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; 调用WinMain函数
invoke ExitProcess, eax                           ; 退出程序


WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX                                            ; 创建stack上的初始变量
    LOCAL msg:MSG
    LOCAL hwnd:HWND
	LOCAL rect:RECT

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; 为wc成员变量设置初始值
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

	;菜单栏
	invoke CreateMenu
    mov hMenu, eax

	invoke CreatePopupMenu
    mov hFileMenu, eax ; 文件菜单
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_OPEN, OFFSET OpenName
    invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVE, OFFSET SaveName
	invoke AppendMenu, hMenu, MF_POPUP, hFileMenu, OFFSET FileName

	invoke CreatePopupMenu
    mov hEditMenu, eax ; 编辑菜单
    invoke AppendMenu, hEditMenu, MF_STRING, IDM_DATE, OFFSET DateName
    invoke AppendMenu, hMenu, MF_POPUP, hEditMenu, OFFSET EditName

	invoke CreatePopupMenu
	mov hViewMenu, eax ; 视图菜单
    invoke AppendMenu, hViewMenu, MF_STRING, IDM_FONT, OFFSET FontName
    invoke AppendMenu, hViewMenu, MF_STRING, IDM_SIZE, OFFSET SizeName
    invoke AppendMenu, hMenu, MF_POPUP, hViewMenu, OFFSET ViewName

    invoke RegisterClassEx, addr wc                       ; 注册窗口类
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
	
	; 设置edit控件
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

    invoke ShowWindow, hwnd, CmdShow               ; 显示窗口
    invoke UpdateWindow, hwnd                      ; 刷新窗口

    .WHILE TRUE                                                       ; 消息循环
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam                                            ; 返回值储存在eax中
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

	; 调整子窗口大小
	.ELSEIF uMsg==WM_SIZE
		mov eax, lParam
		and eax, 0000FFFFh
		mov clientWidth, eax
		mov eax, lParam
		shr eax, 16
		mov clientHeight, eax

		; 重新设置Edit控件大小
		invoke MoveWindow, hEdit, 0, 0, clientWidth, clientHeight, TRUE

	; 菜单栏响应
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
				.while byte ptr [esi] != 0 ; 获取要打开文件的文件名
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
						mov esi, offset curText
						mov ecx, 0
			ClearLoop:
						mov al, [esi + ecx]				; 读取字符串中的一个字符
						cmp al, 0						; 检查字符是否为null（字符串结束符）
						je EndClear						; 如果是null，结束清除
						mov byte ptr [esi + ecx], 0		; 否则，将字符设置为null
						inc ecx							; 增加计数器
						jmp ClearLoop					; 继续处理下一个字符
			EndClear:
						mov ecx, bytesRead
						mov curLen, ecx
						mov	esi, 0;
			CopyLoop:	mov al, byte ptr [pBuffer + esi]
						mov	byte ptr [curText + esi], al
						inc esi
						loop CopyLoop
						; 把文件里的内容显示到edit控件中

						; 选中编辑框中的所有内容
						invoke SendMessage, hEdit, EM_SETSEL, 0, -1

						; 替换为文件内容
						invoke SendMessage, hEdit, EM_REPLACESEL, TRUE, addr curText

						invoke SetFocus, hEdit
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
					; 选择编辑框中的所有文本
					invoke SendMessage, hEdit, EM_SETSEL, 0, -1

					; 获取选中文本的起始和结束位置
					invoke SendMessage, hEdit, EM_GETSEL, addr strStart, addr strEnd

					; 计算选中文本的长度
					mov eax, strEnd
					sub eax, strStart

					; 分配足够的内存来存储选中文本
					inc eax
					invoke GlobalAlloc, GMEM_ZEROINIT, eax
					mov hGlobal, eax

					; 锁定全局内存并获取其指针
					invoke GlobalLock, hGlobal
					mov lpText, eax

					; 获取选中文本
					mov eax, strEnd
					sub eax, strStart
					inc eax
					invoke GetWindowText, hEdit, lpText, eax

					; 解锁全局内存
					invoke GlobalUnlock, hGlobal

					; 保存
					mov ecx, strEnd
					sub ecx, strStart
					invoke WriteFile, hFile, lpText, ecx, addr dwBytesWritten, 0

					; 释放全局内存
					invoke GlobalFree, hGlobal
					
					; 关闭文件句柄
					invoke CloseHandle, hFile

					; 将光标移动到末尾
					invoke SendMessage, hEdit, EM_SETSEL, -1, -1

					; 设置焦点
					invoke SetFocus, hEdit
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