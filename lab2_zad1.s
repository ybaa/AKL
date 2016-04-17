.data
	EXIT	=	1
	READ	=	0
	WRITE 	=	1
	STDOUT	=	1
	STDIN 	= 	0
	SYSCALLEXIT =	60	
	BUF_SIZE = 	100
	komunikat: .ascii "Podaj liczbe \n"
	komunikat_size = .-komunikat
	wynik: .ascii "Wynik = "
	wynik_size = .-wynik
.bss
	.comm	BUF, 100
	.comm	BUF2,100
	.comm	BUF3,100
.text
.global _start
_start:
	CALL pokaz_komunikat
	CALL wczytaj

	CALL konwersja_z_ascii

	push %r8	#pierwsza liczaba na stos
	pop  %r9
	
	CALL pokaz_komunikat
	CALL wczytaj
	CALL konwersja_z_ascii

	add %r9, %r8
	
	CALL pokaz_napis_wynik
	CALL dekonwersja 

	CALL wyjscie

#wczytywanie z klawiatury
wczytaj:
	mov	$READ,     %rax
	mov	$STDIN,    %rdi
	mov	$BUF,	   %rsi
	mov	$BUF_SIZE, %rdx
	syscall
	ret

#wypisywanie
wypisz:
		
	mov	$WRITE,   %rax
	mov	$STDOUT,  %rdi
	mov	$BUF,	  %rsi
	mov	$BUF_SIZE,%rdx
	syscall
	ret

#wyswietlenie pytania o wprowadzana liczebe
pokaz_komunikat:
	mov	$WRITE,   %rax
	mov	$STDOUT,  %rdi
	mov	$komunikat,%rsi
	mov	$komunikat_size, %rdx
	syscall
	ret

#wyswietlenie "wynik="
pokaz_napis_wynik:
	mov	$WRITE,	%rax
	mov	$STDOUT, %rdi
	mov	$wynik,	%rsi
	mov	$wynik_size, %rdx
	syscall
	ret

#wyjscie
wyjscie:
	mov 	$SYSCALLEXIT,	%rax
	mov	$0, %rdi
	syscall
	ret	

#konwersja z ascii
konwersja_z_ascii:
	mov	%rax,	%rdi	#to bedzie licznik do petli
	sub	$2,	%rdi	#ignoruje \n i liczy od 0, a nie od 1
	mov	$1,	%rsi	#kolejne potegi 10
	mov	$0,	%r8	#tu bedzie wynik


petla:
	cmp 	$0,	%rdi	#tu ustawia flage potrzebna dalej
	jl	skonwertowane		#skocz jesli dojdzie do 0
	mov	$0,	%rax	#wyzerowanie rax
	movb	BUF(,%rdi,1),%al #bierze po jednym znaku
	sub	$0x30,	%al	#zrobienie liczby z ascii
	mul	%rsi		#mnozenie rax przez biezaca potege 10
	add	%rax,	%r8	#dodanie obecnego wyniku do ogolnego w r8

	mov	%rsi,	%rax	#wrzucenie obecnej potego do rax
	mov	$10,	%rbx	#podstawa do rbx
	mul	%rbx		#mnozenie x10
	mov	%rax,	%rsi	#wrzucenie nastepna potege do rsi

	dec	%rdi		#zmniejszenie licznika i jeszcze raz
	jmp	petla
	syscall
	ret

skonwertowane:
	ret	#jak zrobilo co ma zrobic to niech przestanie
	
	
	

#dekonwersja	
dekonwersja:
	mov	%r8,	%rax	#wynik do rax
	mov	$10,	%rbx	#podstawa do rbx
	mov	$0,	%rcx	#wyzerowanie rcx - licznika
	
petla2:
	mov	$0,	%rdx	#wyzerowanie rdx
	div	%rbx		#podzielenie przez podstawe...
	add	$0x30,	%rdx	#... a reszta do rdx i zamiana na ascii
	mov	%dl,	BUF2(,%rcx,1) # po 1 znaku
	inc	%rcx		#licznik++
	cmp	$0,	%rax
	jne	petla2

petla3:
	mov	$0,	%rdi	#wyzerowanie licznika
	mov	%rcx,	%rsi	#ile razy obrocic do rsi
	dec	%rsi		#zeby nie zrobilo razy 0

petla3a:
	mov	BUF2(,%rsi,1),%rax
	mov	%rax,	BUF3(,%rdi,1)

	inc	%rdi		#licznik tutejszy++
	dec	%rsi		#licznik poprzedni do odwracania--
	cmp	%rcx,	%rdi
	jle	petla3a
	
	movb	$0xA, BUF3(,%rcx,1)	#przejcie do nowej linii
	inc	%rcx

	mov	$WRITE,     %rax
	mov	$STDOUT,    %rdi
	mov	$BUF3,	   %rsi
	mov	%rcx,	 %rdx
	syscall

	ret

