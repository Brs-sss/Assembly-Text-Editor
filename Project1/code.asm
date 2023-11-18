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

includelib      msvcrt.lib
include         msvcrt.inc

WinMain proto :DWORD,:DWORD,:DWORD,:DWORD

.data                     ; initialized data
ClassName db "SimpleWinClass",0        ; the name of our window class
AppName db "Text Editor",0        ; the name of our window

FileName db "File",0                ; The name of our menu in the resource file.
OpenName db "Open",0
SaveName db "Save",0
SaveAsName db "Save As",0

EditName db "Edit",0
DateName db "Date",0

ViewName db "View",0
FontName db "Font",0
SizeName db "Size",0

szFileName	db	MAX_PATH dup (0)
pBuffer db 4096 dup(0)
szDefExt db "txt",0 ; ����Ĭ����չ��
szFilter	db	'Text Files(*.txt)',0,'*.txt',0,'All Files(*.*)',0,'*.*',0,0

EditClassName db "EDIT"
clientWidth DWORD 0
clientHeight DWORD 0

open_string db "You're trying to open a file while this fuction is not implemented right now! hhh--",0
save_string db "You're trying to save the file while this fuction is not implemented right now! hhh--",0

curText BYTE "nothing", 1000 DUP(0)
curLen DWORD 7
char WPARAM 20h 

hGlobal    dd 0           ; ȫ���ڴ���
lpText     dd 0           ; �ı�������ָ��
strStart   DWORD 0
strEnd     DWORD 0
emptyString db 0

dateBuffer db 64 dup(0)
dateFormat db "%02d:%02d %04d/%02d/%02d ", 0
pathBuffer db 256 dup(0) ; ���ڼ�¼��ǰ�ļ��ѱ����·��

ChsFont db 20 DUP(?)
ChsStyle db 20 DUP(?)
ChsSize db 20 DUP(?)

temp DWORD 0

.data?                ; δ��ʼ��������������
hInstance HINSTANCE ?        ; �����ʵ�����
hMenu HMENU ?
hFileMenu HMENU ?
hEditMenu HMENU ?
hViewMenu HMENU ?
hEdit HWND ?
CommandLine LPSTR ?

systemtime_buffer SYSTEMTIME <> ; ���ڴ洢ϵͳʱ��ı���
hasSaved db, 0
systemtime_buffer SYSTEMTIME <> ; ���ڴ洢ϵͳʱ��ı���


.const
IDM_OPEN equ 1                    ; �˵�ID
IDM_SAVE equ 2
IDM_DATE equ 3
IDM_FONT equ 4
IDM_SIZE equ 5
IDM_SAVEAS equ 6

IDD_SETFONT equ 9                 ; �Ի���ID
IDL_SIZE equ 1004
IDL_STYLE equ 1005
IDL_FONT equ 1008
IDC_FONT equ 1011
IDC_STYLE equ 1012
IDC_FSIZE equ 1015

szWarnCaption	db	'����',0
szCreateWarnMessage	db	'CreateFile����',0
szReadWarnMessage	db	'ReadFile����',0

OpFonts db "Calibri", 0			  ; ��ѡ���塢���ʹ�ϸ
		db "Kaiti", 0			  ; �����֧�����塢���ȣ��˴���Ϊdebugʾ��
		db "MS YaHei", 0          ; ���ĺ�����䶯�������룬ChsX..X�оͻ�洢��Ӧ����
		db "Songti", 0
FontEnd equ $

OpStyles db "bold", 0
		 db "light", 0
		 db "regular", 0
StyleEnd equ $

OpSizes db "100", 0
		db "200", 0
		db "300", 0
		db "400", 0
SizeEnd equ $

infoFont db '����', 0		  ; ��ʾ��Ϣ
infoStyle db '��ϸ', 0
infoSize db '�ֺ�', 0

debugFont db 'Enter font', 0
debugStyle db 'Enter style', 0
debugSize db 'Enter size', 0

.code                ; Here begins our code
start:
invoke GetModuleHandle, NULL            ; ��ȡ�����ʵ�����

mov hInstance,eax
invoke GetCommandLine                        ; ��ȡ�����в���

mov CommandLine,eax
invoke WinMain, hInstance,NULL,CommandLine, SW_SHOWDEFAULT        ; ����WinMain����
invoke ExitProcess, eax                           ; �˳�����

SaveFile proc fileName:DWORD, nameLength:DWORD, dwBytesWritten:DWORD, hFile:HANDLE
	; Try to open file
	invoke CreateFile, fileName, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
	mov hFile, eax
	.if hFile != INVALID_HANDLE_VALUE
		; �޸ı�����Ϣ
		mov ecx, nameLength
		mov esi, fileName
		mov edi, offset pathBuffer
		rep movsb
		mov hasSaved, 1

		; ѡ��༭���е������ı�
		invoke SendMessage, hEdit, EM_SETSEL, 0, -1

		; ��ȡѡ���ı�����ʼ�ͽ���λ��
		invoke SendMessage, hEdit, EM_GETSEL, addr strStart, addr strEnd

		; ����ѡ���ı��ĳ���
		mov eax, strEnd
		sub eax, strStart

		; �����㹻���ڴ����洢ѡ���ı�
		inc eax
		invoke GlobalAlloc, GMEM_ZEROINIT, eax
		mov hGlobal, eax

		; ����ȫ���ڴ沢��ȡ��ָ��
		invoke GlobalLock, hGlobal
		mov lpText, eax

		; ��ȡѡ���ı�
		mov eax, strEnd
		sub eax, strStart
		inc eax
		invoke GetWindowText, hEdit, lpText, eax

		; ����ȫ���ڴ�
		invoke GlobalUnlock, hGlobal

		; ����
		mov ecx, strEnd
		sub ecx, strStart
		invoke WriteFile, hFile, lpText, ecx, addr dwBytesWritten, 0

		; �ͷ�ȫ���ڴ�
		invoke GlobalFree, hGlobal
					
		; �ر��ļ����
		invoke CloseHandle, hFile

		; ������ƶ���ĩβ
		invoke SendMessage, hEdit, EM_SETSEL, -1, -1

		; ���ý���
		invoke SetFocus, hEdit
		.else
			invoke MessageBox, 0, addr szCreateWarnMessage, addr szWarnCaption, MB_ICONERROR or MB_OK
		.endif
		ret
SaveFile endp

CheckFileNameExtension proc lpFileName:DWORD, lpDefExt:DWORD
    ; Ѱ���ļ����е����һ����б��
    invoke StrRChr, lpFileName, 0, '\\'
    mov ecx, eax

    ; ����ҵ���б�ܣ��ƶ�����һ���ַ�
    .if ecx != 0
        inc ecx
    .else
        mov ecx, lpFileName
    .endif

    ; Ѱ���ļ����е����һ�����
    invoke StrRChr, ecx, 0, '.'
    .if eax == 0
        ; ���û�е�ţ�����Ƿ����ͬ���ļ���
        invoke PathIsDirectory, lpFileName
        .if eax == FALSE
            ; ��������ļ��У�׷��Ĭ����չ��
            invoke lstrcat, lpFileName, lpDefExt
        .endif
    .endif

    ret
CheckFileNameExtension endp

WinMain proc hInst:HINSTANCE, hPrevInst:HINSTANCE, CmdLine:LPSTR, CmdShow:DWORD
    LOCAL wc:WNDCLASSEX                                            ; ����stack�ϵĳ�ʼ����
    LOCAL msg:MSG
    LOCAL hwnd:HWND
	LOCAL rect:RECT

    mov   wc.cbSize,SIZEOF WNDCLASSEX                   ; Ϊwc��Ա�������ó�ʼֵ
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
	invoke AppendMenu, hFileMenu, MF_STRING, IDM_SAVEAS, OFFSET SaveAsName
	invoke AppendMenu, hMenu, MF_POPUP, hFileMenu, OFFSET FileName

	invoke CreatePopupMenu
    mov hEditMenu, eax ; �༭�˵�
    invoke AppendMenu, hEditMenu, MF_STRING, IDM_DATE, OFFSET DateName
    invoke AppendMenu, hMenu, MF_POPUP, hEditMenu, OFFSET EditName

	invoke CreatePopupMenu
	mov hViewMenu, eax ; ��ͼ�˵�
    invoke AppendMenu, hViewMenu, MF_STRING, IDM_FONT, OFFSET FontName
    invoke AppendMenu, hViewMenu, MF_STRING, IDM_SIZE, OFFSET SizeName
    invoke AppendMenu, hMenu, MF_POPUP, hViewMenu, OFFSET ViewName

    invoke RegisterClassEx, addr wc                       ; ע�ᴰ����
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

    invoke ShowWindow, hwnd, CmdShow               ; ��ʾ����
    invoke UpdateWindow, hwnd                      ; ˢ�´���

    .WHILE TRUE                                                       ; ��Ϣѭ��
                invoke GetMessage, ADDR msg,NULL,0,0
                .BREAK .IF (!eax)
                invoke TranslateMessage, ADDR msg
                invoke DispatchMessage, ADDR msg
   .ENDW
    mov     eax,msg.wParam                                            ; ����ֵ������eax��
    ret
WinMain endp

; �Ի�����Ϣѭ������
DialogProc PROC hWinDlg:HWND, uMsg:UINT, wParam:WPARAM, lParam:LPARAM
	LOCAL hList:HANDLE

    .IF uMsg == WM_INITDIALOG
        ; ����List����
		mov esi, OFFSET OpFonts
		addFont:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_FONT, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, FontEnd
			jne addFont

		mov esi, OFFSET OpStyles
		addStyle:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_STYLE, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, StyleEnd
			jne addStyle

		mov esi, OFFSET OpSizes
		addSize:
			mov ebx, esi
			invoke SendDlgItemMessage, hWinDlg, IDL_SIZE, LB_ADDSTRING, 0, ebx
			invoke crt_strlen, ebx
			add esi, eax
			inc esi
			cmp esi, SizeEnd
			jne addSize

		; ������ʾ�ı�����
		invoke GetDlgItem, hWinDlg, IDC_FONT
		invoke SetWindowText, eax, OFFSET infoFont

		invoke GetDlgItem, hWinDlg, IDC_STYLE
		invoke SetWindowText, eax, OFFSET infoStyle

		invoke GetDlgItem, hWinDlg, IDC_FSIZE
		invoke SetWindowText, eax, OFFSET infoSize

		mov eax, 1
    .ELSEIF uMsg == WM_COMMAND
        .IF wParam == IDOK
			; TODO: ����edit�ؼ�����
			; ��ǰѡ���������Ѿ���ChsX...X�б��棬ֻ�����Edit�Ľӿڼ��ɣ����ΪhEdit
            invoke EndDialog, hWinDlg, 0
		.ELSEIF wParam == IDCANCEL
			invoke EndDialog, hWinDlg, 0
		.ELSE
			mov ebx, wParam
			mov ecx, wParam
			shr ecx, 16 
			.IF bx == IDL_FONT && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_FONT				; ��ȡlist���
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0		; ��ȡѡ��Ԫ������
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsFont
			.ELSEIF bx == IDL_STYLE && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_STYLE				
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsStyle
			.ELSEIF bx == IDL_SIZE && cx == LBN_SELCHANGE
				invoke GetDlgItem, hWinDlg, IDL_SIZE				
				mov hList, eax
				invoke SendMessage, hList, LB_GETCURSEL, 0, 0
				invoke SendMessage, hList, LB_GETTEXT, eax, ADDR ChsSize
			.ENDIF
        .ENDIF
	.ELSEIF uMsg == WM_CLOSE
		invoke EndDialog, hWinDlg, 0

	; TODO: ��Ӧ������¼ʱ��
    .ENDIF
    xor eax, eax
    ret
DialogProc ENDP

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

	; �����Ӵ��ڴ�С
	.ELSEIF uMsg==WM_SIZE
		mov eax, lParam
		and eax, 0000FFFFh
		mov clientWidth, eax
		mov eax, lParam
		shr eax, 16
		mov clientHeight, eax

		; ��������Edit�ؼ���С
		invoke MoveWindow, hEdit, 0, 0, clientWidth, clientHeight, TRUE

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
				.while byte ptr [esi] != 0 ; ��ȡҪ���ļ����ļ���
					mov al, byte ptr [esi]
					mov byte ptr [szFileName + ecx], al
					inc esi
					inc ecx
				.endw

				; Try to open file
				invoke CreateFile, addr szFileName, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				mov hFile, eax

				.if hFile != INVALID_HANDLE_VALUE
					; ���ñ��������Ϣ
					mov hasSaved, 1
					mov ecx, LENGTHOF szFileName
					mov esi, offset szFileName
					mov edi, offset pathBuffer
					rep movsb
					mov eax, offset szFileName

					invoke ReadFile, hFile, addr pBuffer, 4096, addr bytesRead, NULL
					.if eax != 0 
						mov esi, offset curText
						mov ecx, 0
			ClearLoop:
						mov al, [esi + ecx]				; ��ȡ�ַ����е�һ���ַ�
						cmp al, 0						; ����ַ��Ƿ�Ϊnull���ַ�����������
						je EndClear						; �����null���������
						mov byte ptr [esi + ecx], 0		; ���򣬽��ַ�����Ϊnull
						inc ecx							; ���Ӽ�����
						jmp ClearLoop					; ����������һ���ַ�
			EndClear:
						mov ecx, bytesRead
						mov curLen, ecx
						mov	esi, 0;
			CopyLoop:	mov al, byte ptr [pBuffer + esi]
						mov	byte ptr [curText + esi], al
						inc esi
						loop CopyLoop
						; ���ļ����������ʾ��edit�ؼ���

						; ѡ�б༭���е���������
						invoke SendMessage, hEdit, EM_SETSEL, 0, -1

						; �滻Ϊ�ļ�����
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
			.if hasSaved==0
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
					invoke CheckFileNameExtension, addr szFileName, offset szDefExt
					mov eax, ofn.lpstrFile
						mov esi, eax
						xor ecx, ecx
					.while byte ptr [esi] != 0 ;Get the name of file to be open
						mov al, byte ptr [esi]
						mov byte ptr [szFileName + ecx], al
						inc esi
						inc ecx
					.endw
					invoke SaveFile, addr szFileName, LENGTHOF szFileName, dwBytesWritten, hFile
				.endif
			.else
				invoke SaveFile, addr pathBuffer, LENGTHOF szFileName, dwBytesWritten, hFile
			.endif
		.ELSEIF ax==IDM_SAVEAS
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
				invoke CheckFileNameExtension, addr szFileName, offset szDefExt
				mov eax, ofn.lpstrFile
					mov esi, eax
					xor ecx, ecx
				.while byte ptr [esi] != 0 ;Get the name of file to be open
					mov al, byte ptr [esi]
					mov byte ptr [szFileName + ecx], al
					inc esi
					inc ecx
				.endw
				invoke SaveFile, addr szFileName, LENGTHOF szFileName, dwBytesWritten, hFile
			.endif
		.ELSEIF ax==IDM_DATE
			invoke GetLocalTime, addr systemtime_buffer

			; ��ʱ���ʽ��Ϊ�ַ���
			invoke wsprintf, addr dateBuffer, addr dateFormat, systemtime_buffer.wHour, systemtime_buffer.wMinute, systemtime_buffer.wYear, systemtime_buffer.wMonth, systemtime_buffer.wDay
			; ��ȡEdit�ؼ��ĵ�ǰ�ı�����
			invoke SendMessage, hEdit, WM_GETTEXTLENGTH, 0, 0
			mov edx, eax  ; edx���浱ǰ�ı�����

			mov esi, offset dateBuffer

			; �����㹻���ڴ����洢��ǰ�ı���Ҫ��������ı�
			add edx, 17  ;
			invoke GlobalAlloc, GMEM_ZEROINIT, edx
			mov edi, eax

			invoke SendMessage, hEdit, WM_GETTEXT, edx, edi

			invoke lstrcat, edi, esi

			; �����ı�д��Edit�ؼ�
			invoke SendMessage, hEdit, EM_REPLACESEL, TRUE, edi

			; �ͷ��·�����ڴ�
			invoke GlobalFree, edi
			.ELSEIF ax==IDM_FONT
				invoke DialogBoxParam, hInstance, IDD_SETFONT, NULL, ADDR DialogProc, 0

        .ENDIF
    .ELSE
        invoke DefWindowProc,hWnd,uMsg,wParam,lParam
        ret
    .ENDIF
    xor   eax, eax
    ret
WndProc endp

end start