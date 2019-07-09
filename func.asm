;=====================================================================
; ARKO - projekt 2
;
; Autor: Magdalena Zych
; Data:  2019-05-16
; Opis:  Kodowanie/dekodowanie Huffmana - potrzebne funkcje
;
;=====================================================================
section .data
	readBufLen equ 200
	writeBufLen equ 200 
	statLabel1 db "------Statystyki wystapien znakow i ich kody------", 10
	statLabel2 db "znak jako liczba calkowita - wystapienia - kod", 10

section .bss 
	content resb 1
	contentCount resb 4
	smallestFreq1 resb 4
	index1 resb 4
	smallestFreq2 resb 4
	index2 resb 4
	counter resb 4
	treeAddress resb 4
	codedSigns resb 2
	readBuffor resb readBufLen
	writeBuffor resb writeBufLen
	writeBufCounter resb 4
	fileDesc resb 4
	readSigns resb 4
	node resb 4
	currentByte resb 1
	currentByteCount resb 4
	digitSpace resb 8
	position resb 4
	number resb 4
	tmpNumber resb 4
	code resb 4
	codeCounter resb 2

section	.text
	global doStatistics
	global huffmanTree
	global createCodes
	global countBits
	global codeFile
	global readHeader
	global decodeFile
	global printStatAndCodes

;2 argumenty: adres tablicy statistics, adres naazy pliku wejsciowego
doStatistics:
	push	ebp
	mov	ebp, esp

	mov eax, 5 ;syscall- otwieranie pliku
	mov ebx, [ebp+12] ;2 argument funkcji doStatistics
	mov ecx, 0 ;flaga: 0-read
	mov edx, 0644o ;permissions
	int 0x80 ;opening the file
	push eax ;zapamietanie deskryptora pliku
readInputFileLoop:
	mov eax, 3
	mov ebx, [esp]
	mov ecx, content
	mov edx, 1
	int 0x80 ;przeczytanie znaku z pliku wejsciowego
	cmp eax, 0
	je doStatisticsEnd ;koniec gdy nie wczytano zadnego znaku
	mov eax, dword 0
	mov al, [content]
	shl eax, 2 ;mnozenie przez 4, bo aktualizowana jest tablica liczb 4-bajtowych
	add eax, [ebp+8] ;ustalenie adresu pod ktorym jest aktualizowana wartosc
	mov ebx, dword[eax]
	inc ebx
	mov [eax], ebx
	jmp readInputFileLoop
doStatisticsEnd:	
	mov eax, 6
	pop ebx
	int 0x80 ;zamkniecie pliku	

	pop	ebp
	ret
	
	
;3 argumenty: adres tablicy statistics, adres tablicy tree, wskazanie na ilosc elementow w drzewie
huffmanTree:
	push ebp
	mov ebp, esp
	
	mov eax, dword[ebp+8] ;adres tablicy statistics
	mov ecx, dword 0 ;licznik petli (od 0 do 255)
addInitialEl: ;dodawanie elementow poczatkowych do drzewa
	cmp dword [eax], 0 ;w ebx licznosc znaku o kodzie ecx
	je doNotAddInitialEl
	
	mov ebx, dword[ebp+16] ;wskazanie na aktualna ilosc elementow w drzewie
	mov ebx, dword[ebx] ;ilosc elementow w drzewie
 	shl ebx, 4 ;mnozenie przez 16, bo element drzewa zajmuje 16 bajtow
	add ebx, [ebp+12] ;ustalenie adresu nowego elementu
	mov edx, dword[eax] ;4 bajty - licznosc
	mov [ebx], dword edx
	mov [ebx+4], cx ;2 bajty
	
	mov edx, dword[ebp+16] ;wskazanie na aktualna ilosc elementow w drzewie
	mov ebx, dword [edx] ;ilosc elementow w drzewie
	inc ebx
	mov [edx], ebx
doNotAddInitialEl:
	add eax, 4 ;zmiana adresu na kolejny element tablicy statistics
	add ecx, 1 ;zwiekszenie licznika
	cmp ecx, 256
	jne addInitialEl
	;dodawanie elementow poczatkowych skonczone, nizej tworzenie drzewa huffmana
	mov ecx, [ebp+16]
	mov ecx, [ecx]
	sub ecx, 1 
	mov [counter], ecx ;licznik w zewnetrznej petli - petla ma sie wykonac (ilosc_elementow-1) razy
treeLoop:
	mov [smallestFreq1], dword 0xFFFFF
	mov [index1], dword 0
	mov ecx, dword 1 ;licznik w wewnetrznej petli
	mov edx, dword[ebp+12] ;adres drzewa
findFirst: ;szukanie pierwszej najmniejszej licznosci i indeksu danego elementu
	mov eax, dword[edx] ;aktualna licznosc
	mov bx, word[edx+6] ;flaga
	cmp bx, 0
	jne firstBigger ;element byl juz uzyty
	cmp eax, [smallestFreq1]
	jge firstBigger ;za duza licznosc
	;zmiana najlepszego znalezionego elementu
	mov [smallestFreq1], eax
	mov [index1], ecx
firstBigger:
	add edx, 16
	inc ecx
	mov eax, [ebp+16]
	mov eax, [eax]
	cmp ecx, eax
	jle findFirst
	;wszystkie elementy zostaly przejrzane pierwszy raz, ustawienie flagi znalezionego elementu
	mov eax, dword[index1]
	shl eax, 4
	sub eax, 16
	add eax, dword[ebp+12] ;adres znalezionego elementu
	mov [eax+6], word 1 ;flaga ustawiona

	mov [smallestFreq2], dword 0xFFFFF
	mov [index2], dword 0
	mov ecx, 1
	mov edx, dword[ebp+12] ;adres drzewa
	
findSecond: ;szukanie pierwszej najmniejszej licznosci i indeksu danego elementu
	mov eax, dword[edx] ;aktualna licznosc
	mov bx, word[edx+6] ;flaga
	cmp bx, 0
	jne secondBigger ;element byl juz uzyty
	cmp eax, [smallestFreq2]
	jge secondBigger ;za duza licznosc
	;zmiana najlepszego znalezionego elementu
	mov [smallestFreq2], eax
	mov [index2], ecx
secondBigger:
	add edx, 16
	inc ecx
	mov eax, [ebp+16]
	mov eax, [eax]
	cmp ecx, eax
	jle findSecond
	;wszystkie elementy zostaly przejrzane pierwszy raz, ustawienie flagi znalezionego elementu
	mov eax, dword[index2]
	shl eax, 4
	sub eax, 16
	add eax, dword[ebp+12] ;adres znalezionego elementu
	mov [eax+6], word 1 ;flaga ustawiona
;dodawanie elementu do drzewa
	mov eax, [ebp+16]
	mov ebx, [eax]
	inc ebx
	mov [eax], ebx ;zwiekszenie ilosci elementow w drzewie
	mov edx, [counter]
	dec edx ;zmniejszenie licznika
	mov [counter], edx
	shl ebx, 4
	add ebx, [ebp+12]
	sub ebx, 16 ;adres nowego elementu
	
	mov eax, [smallestFreq1]
	add eax, [smallestFreq2]
	mov [ebx], eax ;licznosc nowego elementu
	mov [ebx+4], word 0 ;wyzerowanie znaku
	mov [ebx+6], word 0 ;wyzerowanie flagi
	mov eax, dword[index1]
	mov [ebx+8], eax ;zapisanie lewego potomka nowego elementu
	mov eax, dword[index2]
	mov [ebx+12], eax ;zapisanie prawego potomka nowego elementu
	mov edx, [counter]
	cmp edx, 0
	jne treeLoop
	;dodano wszystkie elementy
resetTreeBits:
	mov eax, dword[ebp+12] ;edres drzewa
	mov ecx, dword[ebp+16]
	mov ecx, dword[ecx] ;licznik
resetTreeBitsLoop:
	mov [eax], dword 0
	mov [eax+6], word 0
	dec ecx
	add eax, 16
	cmp ecx, 0
	jne resetTreeBitsLoop
	
	pop ebp
	ret
	
;2 argumenty - adres drzewa, ilosc elementow w drzewie
createCodes:
	push ebp
	mov ebp, esp
	mov eax, [ebp+8]
	mov [treeAddress], eax ;adres drzewa
	mov ebx, [ebp+12] ;ilosc elementow w drzewie
	push ebx ;1 argument funkcji preorder - nr wierzcholka dla ktorego jest wywolywana funkcja [ebp+20]
	push dword 2 ;2 argument funkcji preorder - tryb wywolania (root/lewy/prawy) [ebp+16]
	push dword 0 ;3 argument funkcji preorder - licznosc bitow funkcji wywolujacej [ebp+12]
	push dword 0 ;4 argument funkcji preorder - bity [ebp+8]
	call preorder
	pop ebx
	pop ebx
	pop ebx
	pop ebx
	
	pop ebp
	ret

;rekursywna funkcja przyjmujaca 4 argumenty
preorder:
	push ebp
	mov ebp, esp
	
	mov eax, dword[ebp+20]
	sub eax, 1
	shl eax, 4
	add eax, dword[treeAddress] ;adres aktualnego wierzcholka
	
	mov ebx, dword[ebp+16] ;tryb wywolania
	cmp ebx, 2
	je nicNieDopisuj
	;cos bedzie dopisywane - zwieksz ilosc bitow
	mov ecx, dword[ebp+12]
	inc ecx
	mov [eax+6], cx
	mov [ebp+12], ecx
	cmp ebx, 1
	je dopisz1
	cmp ebx, 0
	je dopisz0
dopisz1:
	mov ebx, dword[ebp+8] ;bity kodujace
	shl ebx, 1
	or ebx, 1
	mov [eax], ebx
	mov [ebp+8], ebx
	jmp nicNieDopisuj
dopisz0:	
	mov ebx, dword[ebp+8] ;bity kodujace
	shl ebx, 1
	mov [eax], ebx
	mov [ebp+8], ebx
nicNieDopisuj:
	mov ebx, [eax+8] ;wczytanie lewego
	cmp ebx, 0
	je brakLewegoPotomka ;w przeciwnym wypadku wywolanie preorder dla lewego potomka
	push ebx ;arg1
	push 0 ;arg2
	mov ebx, 0
	mov bx, word[eax+6]
	push ebx ;arg3 
	push dword[eax] ;arg4
	call preorder
	pop ebx
	pop ebx
	pop ebx
	pop ebx
brakLewegoPotomka:
	mov eax, dword[ebp+20]
	sub eax, 1
	shl eax, 4
	add eax, dword[treeAddress] ;adres aktualnego wierzcholka
	mov ebx, [eax+12] ;wczytanie prawego
	cmp ebx, 0
	je brakPrawegoPotomka ;w przeciwnym wypadku wywolanie preorder dla prawego potomka
	push ebx ;arg1
	push 1 ;arg2
	mov ebx, 0
	mov bx, word[eax+6]
	push ebx ;arg3 
	push dword[eax] ;arg4
	call preorder
	pop ebx
	pop ebx
	pop ebx
	pop ebx
brakPrawegoPotomka:	
	;koniec funkcji
	pop ebp
	ret

	
;obliczanie ilosci bitow w pliku zakodowanym, 4 argumenty - adres tablicy statistics, adres drzewa, wskaznik na wyznaczona liczbe bitow, liczba elementow w drzewie
countBits:
	push ebp
	mov ebp, esp
	
	mov ecx, dword[ebp+20] ;liczba elementow
	inc ecx
	shr ecx, 1 ;licznik = liczba lisci
	mov ebx, [ebp+12] ;adres drzewa
countBitsLoop:
	mov eax, dword 0
	mov ax, word[ebx+4] ;znak 
	shl eax, 2 
	add eax, [ebp+8] ;adres licznosci danego znaku w tablicy statistics
	mov eax, [eax] ;liczba wystapien danego znaku
	mul word[ebx+6] 

	mov edx, [ebp+16]
	mov edx, [edx]
	add edx, eax ;zwiekszenie liczby bitow
	mov edi, [ebp+16]
	mov [edi], edx
	
	dec ecx
	add ebx, 16
	cmp ecx, 0
	jne countBitsLoop
	
	pop ebp
	ret
	
	
;pisanie naglowka i kodowanie pliku, 6 argumenty - adres tablicy statistics, adres nazwy pliku wejsciowego, adres nazwy pliku wyjsciowego, wskazanie na liczbe bitow kodujacych
;liczba elementow w drzewie, adres drzewa
codeFile:
	push ebp
	mov ebp, esp
	
	;otworzenie pliku wejsciowego
	mov eax, 5 ;syscall- otwieranie pliku
	mov ebx, [ebp+12] ;2 argument funkcji codeFile
	mov ecx, 0 ;flaga: 0-read
	mov edx, 0644o ;permissions
	int 0x80 ;opening the file
	push eax ;zapamietanie deskryptora pliku
	;otworzenie pliku wyjsciowego
	mov eax, 5 ;syscall- otwieranie pliku
	mov ebx, [ebp+16] ;3 argument funkcji codeFile
	mov ecx, 65 ;flagi: 64-create + 1-write
	mov edx, 0644o ;permissions
	int 0x80 ;opening the file
	mov [fileDesc], eax
	push eax ;zapamietanie deskryptora pliku
	
	;zapisanie ilosci kodowanych znakow (2 bajty)
	mov eax, 4
	mov ebx, [esp]
	mov ecx, [ebp+24] ;liczba elementow w drzewie
	inc ecx
	shr ecx, 1 ;liczba kodowanych znakow
	mov [codedSigns], cx
	mov ecx, codedSigns
	mov edx, 2
	int 0x80
	;petla zapisujaca dla kazdego znaku: znak(1 bajt)-licznosc(2 bajty)
	mov [counter], dword 0
writeHeaderLoop:
	mov eax, 4
	mov ebx, [esp]
	mov ecx, dword [counter]
	shl ecx, 4
	add ecx, [ebp+28]
	mov [treeAddress], ecx ;zapisanie adresu elementuw drzewie w zmiennej treeAddress
	add ecx, 4
	mov edx, 1
	int 0x80 ;pisanie znaku
	
	mov eax, 4
	mov ebx, [esp]
	mov cl, byte[ecx]
	and ecx, 0x000000FF ;znak
	shl ecx, 2
	add ecx, [ebp+8] ;adres licznosci znaku w tablicy statistics
	mov edx, 2
	int 0x80
	
	;zapisanie w tablicy statistics adresu elementu w drzewie odpowiadajacego danemu znakowi
	mov eax, dword[treeAddress]
	mov [ecx], eax
	
	mov eax, [counter]
	inc eax
	mov [counter], eax
	cmp eax, [codedSigns]
	jl writeHeaderLoop
	;zapisanie ilosci bitow kodujacych plik (4 bajty)
	mov eax, 4
	mov ebx, [esp]
	mov ecx, [ebp+20]
	mov edx, 4
	int 0x80
	;kodowanie pliku
	mov [content], byte 0 ; w zmiennej content beda przechowywwane bity ktore maja byc zapisane do pliku wyjsciowego
	mov [contentCount], dword 8 ;licznik ktory bedzie przechowywal informacje o tym ile jeszcze bitow mozna zapisac w content zanim bajt zostanie przekazany do bufora wyjsciowegpo
	mov [writeBufCounter], dword 0 ;licznik - przechowuje informacje o tym ile bajtow jest juz zapisanych w buforze wyjsciowym 
readFileLoop:
	mov eax, 3
	mov ebx, [esp+4]
	mov ecx, readBuffor
	mov edx, readBufLen
	int 0x80
	cmp eax, 0
	je endCoding ;nie przeczytano zadnego znaku - koniec pliku
	push eax ;ilosc wczytanych znakow [esp+6]
	mov [counter], dword 0
readSignLoop:
	mov eax, [counter]
	add eax, readBuffor
	mov ecx, dword 0
	mov cl, byte[eax] ;aktualnie przetwarzany znak
	shl ecx, 2
	add ecx, dword[ebp+8] ;adres znaku w tablicy statistics
	mov ecx, dword[ecx] ;adres danego znaku w drzewie
	mov eax, dword[ecx] ;bity kodujace 
	push eax ;[esp+2]
	mov bx, word[ecx+6] ;ilosc  bitow kodujacych
	push bx ;[esp]
	
	mov ax, 16
	sub ax, word[esp] ;tyle razy trzeba przesunac bity kodujace w lewo, przesuwam tak zeby pierwszy bit ktory chce pisac byl najstarszym bietm rejestra bh
	mov dx, word[esp] ;dx bedzie licznikiem w writeCodingBit
	mov ebx, dword[esp+2]
	mov cx, word 0
shiftloop: ;przesuwanie bitow kodujacych do lewej strony rejestru ebx
	cmp cx, ax
	je writeCodingBit
	shl ebx, 1
	inc cx
	jmp shiftloop
writeCodingBit:
	mov al, bh
	and al, 0x80 ;info o tym czy bedzie pisane 0 czy 1	
	mov cl, [content]
	shl cl, 1
	cmp al, 0
	je doNotWriteOne
	or cl, 1
doNotWriteOne:
	mov [content], cl
	mov ecx, dword[contentCount]
	dec ecx
	mov [contentCount], ecx ;zmniejszenie ilosci bitow ktore mozna jeszcze zapisac w content
	cmp ecx, 0
	jne continue
	call writeByte
continue:
	shl ebx, 1
	dec dx
	cmp dx, 0
	jne writeCodingBit
	
	pop bx
	pop eax
	mov eax, dword[counter]
	inc eax
	mov [counter], eax
	cmp eax, [esp]
	jne readSignLoop ;jeszcze nie przetworzono wszystkich znakow z bufora
	pop eax
	jmp readFileLoop ;zaladowanie kolejnych znakow do bufora
	
endCoding:
	cmp [contentCount], dword 8
	je noMoreBitsToWrite
	mov eax, [content]
	mov ebx, dword 0
shiftContentLoop: ;przesuwanie w lewo tak zeby zapisywany bajt byl dopelniony zerami z prawej strony
	shl eax, 1
	inc ebx
	cmp ebx, [contentCount]
	jne shiftContentLoop
	mov [content], eax
	call writeByte
noMoreBitsToWrite:
	cmp [writeBufCounter], dword 0 ;ilosc bajtow w buforze
	je emptyBuffor ;w buforze nie ma zadnych bajtow do zapisania
	mov eax, 4
	mov ebx, [fileDesc]
	mov ecx, writeBuffor
	mov edx, [writeBufCounter]
	int 0x80 ;zapis niepelnego bufora
emptyBuffor:
	;zamkniece pliku wyjsciowego
	mov eax, 6
	pop ebx
	int 0x80
	;zamkniecie pliku wejsciowego
	mov eax, 6
	pop ebx
	int 0x80
		
	pop ebp
	ret
	

writeByte:
	push ebp
	mov ebp, esp
	push ebx
	push edx
	;zapis bajtu do bufora
	mov ebx, dword[writeBufCounter] ;ilosc bajtow zajetych w buforze
	add ebx, writeBuffor ;adres miejsca w ktorym trzeba zapisac dany bajt
	mov cl, byte[content]
	mov [ebx], cl ;zapisanie bajtu
	mov ebx, dword[writeBufCounter]
	inc ebx
	mov [writeBufCounter], ebx ;zwiekszenie liczby bajtow zajetych w buforze
	cmp ebx, writeBufLen
	jne doNotWriteBuffor
doWriteBuffor:
	;pisanie
	mov eax, 4
	mov ebx, [fileDesc];[esp+30]	
	mov ecx, writeBuffor
	mov edx, [writeBufCounter]
	int 0x80
	mov [writeBufCounter], dword 0 ;licznik - przechowuje informacje o tym ile bajtow jest juz zapisanych w buforze wyjsciowym 
doNotWriteBuffor:
	;zresetowanie odpowiednich wartosci
	mov [content], byte 0 ; w zmiennej content beda przechowywwane bity ktre maja byc zapisane do pliku wyjsciowego
	mov [contentCount], dword 8 ;licznik ktory bedzie przechowywal informacje o tym ile jeszcze bitow mozna zapisac w content zanim bajt zostanie przekazany do bufora wyjsciowegpo
	pop edx
	pop ebx
	pop ebp
	ret
	

;otworzenie pliku wejsciowego i odczytanie naglowka, 3 argumenty - adres tablicy statistics, adres nazwy pliku wejsciowego, wskazanie na liczbe bitow kodujacych 
readHeader:
	push ebp
	mov ebp, esp
	
	;otworzenie pliku wejsciowego
	mov eax, 5 ;syscall- otwieranie pliku
	mov ebx, [ebp+12] ;2 argument funkcji readHeader
	mov ecx, 0 ;flaga: 0-read
	mov edx, 0644o ;permissions
	int 0x80 ;opening the file
	push eax ;zapamietanie deskryptora pliku
	
	;odczyt ilosci kodowanych znakow
	mov eax, 3
	mov ebx, [esp]
	mov ecx, codedSigns
	mov edx, 2
	int 0x80
readHeaderLoop: 	
	mov eax, 3
	mov ebx, [esp]
	mov ecx, content
	mov edx, 1
	int 0x80 ;odczyt kodowanego znaku
	
	mov eax, 3
	mov ebx, [esp]
	mov ecx, 0
	mov cl, byte [content]
	shl ecx, 2
	add ecx, [ebp+8] ;w ecx adres odczytanego znaku w tablicy statistics
	mov edx, 2 
	int 0x80
	
	mov ax, word[codedSigns]
	dec ax
	mov [codedSigns], ax
	cmp ax, word 0
	jne readHeaderLoop
	
	mov eax, 3
	mov ebx, [esp]
	mov ecx, [ebp+16]
	mov edx, 4
	int 0x80 ;odczyt ilosci bitow kodujacych
	
	;zapis deskryptora pliku, bedzie potrzebny przy dekodowaniu
	pop ebx
	mov [fileDesc], ebx
	
	pop ebp
	ret
	
;dekodowanie pliku wejsciowego, 4 argumenty - adres drzewa, adres nazwy pliku wyjsciowego, liczba bitow kodujacych plik, liczba elementow w drzewie
decodeFile:
	push ebp
	mov ebp, esp
	
	mov eax, [fileDesc]
	push eax  ;deskryptor pliku wejsciowego jako [esp]
	;otworzenie pliku wyjsciowego
	mov eax, 5 ;syscall- otwieranie pliku
	mov ebx, [ebp+12] ;2 argument funkcji decodeFile
	mov ecx, 65 ;flagi: 64-create + 1-write
	mov edx, 0644o ;permissions
	int 0x80 ;opening the file
	mov [fileDesc], eax ;deskryptor pliku wyjsciowego jako [fileDesc]
	
;czytanie do bufora, potem przetwarzanie po kolei kazdego znaku z bufora i ewentualne zapisywanie do pliku wyjsciowego gdy dotrze sie do liscia
	mov [writeBufCounter], dword 0 ;licznik - przechowuje informacje o tym ile bajtow jest juz zapisanych w buforze wyjsciowym 
	mov eax, [ebp+20]
	mov [node], eax ;biezacy wierzcholek, poczatkowo to korzen
readText:
	mov eax, 3 ;syscall- czytanie z pliku
	mov ebx, [esp]
	mov ecx, readBuffor
	mov edx, readBufLen
	int 0x80
	cmp eax, 0
	je endDecoding ;nie wczytano zadnego znaku - koniec dekodowania
	mov [readSigns], eax ;zapis w zmiennej readSigns ilosci wczytanych znakow
	mov [counter], dword 0 ;zapis w zmiennej counter numeru przetwarzanego znaku (z bufora readBuffor)
decodeByte: ;przetwarzanie pojedynczego bajtu
	mov eax, [counter]
	add eax,  readBuffor
	mov al, byte[eax]
	mov [currentByte], al ;aktualny bajt w zmiennej currentByte
	mov [currentByteCount], dword 8 ;licznik sprawdzajacy czy trzeba pobrac kolejny bajt
	;....................................................................
	takeBit:
	mov al, byte[currentByte]
	mov bl, al
	and bl, 0x80 ;w bl przetwarzany bit
	shl eax, 1 ;przesuniecie w lewo zeby przy kolejnym obiegu petli wziac kolejny bit
	mov [currentByte], al
	
	mov edx, [node]
	dec edx
	shl edx, 4
	add edx, [ebp+8] ;adres aktualnego wierzcholka w drzewie
	
	cmp bl, 0 ;aktualny bit
	je goToLeftSon
	jmp goToRightSon
goToLeftSon:
	add edx, 8
	jmp sonDone
goToRightSon:
	add edx, 12
sonDone:
	mov edx, [edx]
	mov [node], edx ;nowy wierzcholek
	dec edx
	shl edx, 4
	add edx, [ebp+8] ;adres noweace go wierzcholka w drzewie
	mov eax, edx
	add edx, 8
	cmp [edx], dword 0 ;sprawdzenie czy nowy wierzcholek ma lewego potomka
	jne doNotWriteSymbol ;jesli tak to znaczy ze nowy wierzcholek nie jest lisciem
	;funkcja dotarla do liscia, trzeba go wpisac do bufora w celu wypisania do pliku wyjsciowego (funkcja writeByte)
	add eax, 4 ;adres znaku ktory trzeba wypisac
	mov ax, word[eax] ;w ax znak ktory trzeba wypisac
	mov [content], al
	mov eax, [ebp+20];zmiana aktualnego wierzcholka na korzen
	mov [node], eax 
	call writeByte
doNotWriteSymbol:
	mov eax, [ebp+16] ; laczna ilosc bitow ktore trzeba jeszcze pobrac
	dec eax
	mov [ebp+16], eax
	cmp eax, 0
	je endDecoding ;pobrano juz wszystkie bity kodujace plik
	mov eax, [currentByteCount]
	dec eax
	mov [currentByteCount], eax ;zmniejszenie licznika sprawdzajacego czy trzeba pobrac kolejny bajt
	cmp eax, 0
	jne takeBit ;jeszcze nie trzeba pobierac kolejnego bajtu
	;..........................................................
	
	mov eax, [counter]
	inc eax
	mov [counter], eax
	cmp eax, [readSigns]
	jne decodeByte ;jeszcze nie przetworzono wszystkich znakow wczytanych do bufora
	jmp readText
		
endDecoding:
	cmp [writeBufCounter], dword 0
	je bufforIsEmpty ;brak znakow do wypisania w buforze
	mov eax, 4
	mov ebx, [fileDesc]
	mov ecx, writeBuffor
	mov edx, [writeBufCounter]
	int 0x80 ;zapis niepelnego bufora
bufforIsEmpty:
	;zamkniece pliku wejsciowego
	mov eax, 6
	pop ebx
	int 0x80
	;zamkniecie pliku wyjscioweace go
	mov eax, 6
	mov ebx, [fileDesc]
	int 0x80
	
	pop ebp
	ret
	

;wypisanie liczby znajdujacej sie w zmiennej number
printDigit:
	push ebp
	mov ebp, esp

	mov [digitSpace], dword 0
	mov [digitSpace+4], dword 0
	mov [position], dword 0
	mov eax, [number]

printDigitLoop:
	mov ebx, 10
	mov edx, 0
	div ebx ; w eax wynik, w edx reszta z dzielenia 
	mov ebx, [position]
	add ebx, digitSpace ;adres aktualnego znaku
	add dl, byte '0'
	mov [ebx], dl
	mov ebx, [position]
	inc ebx
	mov [position], ebx ;zwiekszenie pozycji dla nastepnej cyfry
	cmp eax, 0
	jne printDigitLoop

printDigitLoop2:
	mov eax, 4
	mov ebx, 1
	mov ecx, [position]
	add ecx, digitSpace ;adres pisanego znaku
	mov edx, 1
	int 0x80

	mov eax, [position]
	dec eax
	mov [position], eax	
	cmp eax, 0
	jge printDigitLoop2

	pop ebp
	ret
	

;wyswietlanie statystyk wystapien znakow w tekscie i kodow znakow
printStatAndCodes:
	push ebp
	mov ebp, esp

	;wyswietlenie labeli
	mov eax, 4
	mov ebx, 1
	mov ecx, statLabel1
	mov edx, 51
	int 0x80

	mov eax, 4
	mov ebx, 1
	mov ecx, statLabel2
	mov edx, 50
	int 0x80

	mov [counter], dword 0
	mov eax, [ebp+12]
	mov [treeAddress], eax ;adres drzewa, po kazdym wypisywaniu zmiana adresu na kolejny element
printStatLoop:
	mov eax, [counter]
	shl eax, 2
	add eax, [ebp+8];edres aktualnego znaku
	mov ebx, dword[eax] ;licznosc danego znaku
	mov [tmpNumber], ebx ;zapisanie aktualnej licznosci
	cmp ebx, 0
	je doNotPrintStat

	;wyswietlenie znaku
	mov eax, dword [counter]
	mov [number], eax
	call printDigit

	;myslinik
	mov [content], byte '-'
	mov eax, 4
	mov ebx, 1
	mov ecx, content
	mov edx, 1
	int 0x80

	;licznosc
	mov eax, dword [tmpNumber]
	mov [number], eax
	call printDigit

	;myslinik
	mov [content], byte '-'
	mov eax, 4
	mov ebx, 1
	mov ecx, content
	mov edx, 1
	int 0x80

	;kod
	mov ebx, dword[treeAddress]
	mov ebx, [ebx] ;bity kodujace dany znak
	mov [code], ebx ;ebx wazne do shiftLeftLoop
	mov eax, dword[treeAddress] ;adres elementu w drzewie
	mov ax, word[eax+6] ;ilosc bitow kodujacych 
	mov [codeCounter], ax
	mov cx, word 16
	sub cx, ax ;tyle razy trzeba zrobic przesuniecie w lewo kodu
	
	mov eax, [treeAddress]
	add eax, 16
	mov [treeAddress], eax ;ziana adresu elementu na kolejny
shiftLeftLoop:
	cmp cx, word 0
	je endShiftLeftLoop
	shl ebx, 1
	dec cx
	jmp shiftLeftLoop
endShiftLeftLoop:
	mov [code], ebx
printCodeLoop:
	mov eax, dword[code]
	mov ebx, dword[code]
	shl ebx, 1
	mov [code], ebx
	and ah, 0x80
	cmp ah, 0
	je printZero
	;w przeciwnym wypadku wyswietlic 1
	mov [content], byte '1'
	jmp continuePrinting
printZero:
	mov [content], byte '0'
continuePrinting:
	mov eax, 4
	mov ebx, 1
	mov ecx, content
	mov edx, 1
	int 0x80 ;wypisanie jednego znaku kodu
	mov ax, word[codeCounter]
	dec ax
	mov [codeCounter], ax
	cmp ax, 0
	jne printCodeLoop ;jeszcze nie wypisano wszytskich znakow kodu
	
	;znak nowej linii
	mov [content], byte 10
	mov eax, 4
	mov ebx, 1
	mov ecx, content
	mov edx, 1
	int 0x80
	
doNotPrintStat:
	mov eax, dword[counter]
	inc eax
	mov [counter], eax
	cmp eax, 256
	jl printStatLoop ;nie sprawdzono jeszcze wszystkich znakow

	pop ebp
	ret
