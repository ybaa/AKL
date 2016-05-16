.data
STDIN = 0
STDOUT = 1
READ = 0
WRITE = 1
SYSEXIT = 60
EXIT_SUCCESS = 0

.bss
.comm ascii1, 1024	# bufor dla pierwszej cyfry w ascii
.comm ascii2, 1024	# bufor dla drugiej
.comm ascii_out, 1024 	# Bufor przechowujący wynik dodawania                    		
                      	
.comm value1, 512 	# Bufor przechowujący pierwszą liczbę w postaci bajtowej
.comm value2, 512 	
.comm value_out, 512 	

.text
.globl _start
_start:

# czyta pierwszy ciag
	mov $READ, %rax
	mov $STDIN, %rdi
	mov $ascii1, %rsi
	mov $1024, %rdx
	syscall

# dekodowanie ciagu 1
	mov %rax, %r8 	# dlugosc do r8
	dec %r8      	# Nie potrzebujemy znaku końca linii

	mov %r8, %r15   # do ogarniczen zeby nie wyswietlalo miliona zer pozniej

	mov $512, %r9 	# Licznik do pętli

dekodowanie:
	dec %r8
	dec %r9

# zmiana na wartosć pierwszych 4
	mov ascii1(, %r8, 1), %al

# sprawdzenie czy znak jest litera czy liczba
	cmp $'A', %al
	jge litera

# Jeśli cyfra 
	sub $'0', %al
	jmp nastepny_znak

# Jeśli litera
litera:
	sub $55, %al


nastepny_znak:

# Wyskok z pętli jeśli zdekodowano ostatnią cyfrę z bufora valueX_in
	cmp $0, %r8
	jle koniec_cyfry

# zamiana kolejnych 4 bitów
	mov %al, %bl
	dec %r8
	mov ascii1(, %r8, 1), %al

	cmp $'A', %al
	jge litera2

	sub $'0', %al
	jmp ustaw_pozycje

litera2:
	sub $55, %al

ustaw_pozycje:
# Ustawienie na odpowiednich pozycjach tych 4 bitów na odpowiednich pozycjach 
	shl $4, %al
	add %bl, %al

# Zapisanie zdekodowanego bajtu danych do nowego bufora
koniec_cyfry:
	mov %al, value1(, %r9, 1)

# Powrót na początek pętli, aż do zdekodowania całego ciągu
	cmp $0, %r8
	jg dekodowanie



# ta sama procedura z nastepna cyfra
	mov $READ, %rax
	mov $STDIN, %rdi
	mov $ascii2, %rsi
	mov $1024, %rdx
	syscall


	mov %rax, %r8
	dec %r8

	mov %r8, %r14 # do pozbycia sie pozniej zer

	mov $512, %r9

dekodowanie_2:
	dec %r8
	dec %r9

# zamiana pierwszych 4 bitów
	mov ascii2(, %r8, 1), %al

	cmp $'A', %al
	jge litera3

	sub $'0', %al
	jmp nastepny_znak_2

litera3:
	sub $55, %al

nastepny_znak_2:
	cmp $0, %r8
	jle koniec_cyfry_2 

# zamiana koljnych 4 bitów
	mov %al, %bl
	dec %r8
	mov ascii2(, %r8, 1), %al

	cmp $'A', %al
	jge litera4

	sub $'0', %al
	jmp ustaw_pozycje_2

litera4:
	sub $55, %al

ustaw_pozycje_2:

	mov $16, %cl
	mul %cl
	add %bl, %al

# Zapisanie zdekodowanej bajtu do nowego bufora
koniec_cyfry_2:
	mov %al, value2(, %r9, 1)

	cmp $0, %r8
	jg dekodowanie_2



# DODANIE OBU WARTOSCI
	clc       	# Wyczyszczenie flagi przeniesienia z poprzedniej pozycji
	pushfq        	# l rejeastru flagowego na stosie
	mov $63, %r8 	# Licznik do pętli
	 
	petla4:
	mov value1(, %r8, 8), %rax	# Odczyt wartości z buforów do rax i rbx
	bswap %rax			# lustrzana zamiana

	mov value2(, %r8, 8), %rbx		
	bswap %rbx

	popfq        	# Pobranie zawartości rejestru flagowego ze stosu
		     	
	adc %rbx, %rax
	push %rax	# Dodanie z propagacją i przyjęciem przeniesienia
	pushfq       	# Umieszczenie rejestru flagowego na stosie
	
	 
	dec %r8    	# Zmniejszenie licznika pętli i powrót na jej początek
	cmp $0, %r8 	# aż do wykonania dodawania dla każdej pozycji w buforze wynikowym.
	jg petla4
	
	mov $0, %r8

tutaj:
	pop %rax	#pobranie ze stosu wyniki
	bswap %rax	#lustrzana zamiana
	mov %rax, value_out(,%r8,8)	#wynik do wyjsciowego
	inc %r8
	cmp $64, %r8
	jne tutaj

#zamiana na hexa
	mov $512, %r8 
	mov $1024, %r9
	mov $0, %rbx
	mov $0, %rcx
	mov $0, %rax

petla5:
	mov value_out(,%r8, 1), %al
	mov %al, %bl
	mov %al, %cl
	and $0b00001111, %bl
	and $0b11110000, %cl
	shr $4, %cl
	add $'0', %bl
	add $'0', %cl

	cmp $'9', %bl
	jle dalej
	add $7, %bl

dalej:
	cmp $'9', %cl
	jle dalej2
	add $7, %cl

dalej2:
	mov %bl, ascii_out(,%r9, 1)
	dec %r9
		
	mov %cl, ascii_out(,%r9, 1)
	dec %r9

	dec %r8

	cmp $0, %r8
	jge petla5

	
#ile wypisac
	cmp %r14, %r15
	jg wieksza

	mov %r14, %r15

wieksza:
	add $3, %r15
	mov $1024, %r14
	sub %r15, %r14
	
	inc %r14 #tyle zer
usun_zera:
	dec %r14
	movb $0x00, ascii_out(,%r14,1)
	cmp $0, %r14
	jge usun_zera

	
#wyswietlenie wyniku
	movq $1023, %r8
	movb $0x0A, ascii_out(,%r8,1) #enter
	mov $WRITE, %rax
	mov $STDOUT, %rdi
	mov $ascii_out, %rsi
	mov $1024, %rdx
	syscall



# ZWROT WARTOŚCI EXIT_SUCCESS
mov $SYSEXIT, %rax
mov $EXIT_SUCCESS, %rdi
syscall

