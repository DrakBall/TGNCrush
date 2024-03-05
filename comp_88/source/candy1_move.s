@;=                                                         	      	=
@;=== candy1_move: rutinas para contar repeticiones y bajar elementos ===
@;=                                                          			=
@;=== Programador tarea 1E: gerard.roman@estudiants.urv.cat		      ===
@;=== Programador tarea 1F: gerard.roman@estudiants.urv.cat		      ===
@;=== Programador tarea 2Ic: gerard.roman@estudiants.urv.cat		  ===
@;=== Programador tarea 2Id: gerard.roman@estudiants.urv.cat		  ===
@;=                                                         	      	=



.include "../include/candy1_incl.i"

@; Mascara d'acces a les diferents parts de la codificacio d'elements
ELEMENT_MASK = 0x7
JELLY_MASK = 0x18

@; Codificacio de diferents elements d'interes
EMPTY_TYPE = 0x0
VOID_TYPE = 0xf
SOLID_TYPE = 0x7

@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1E;
@; cuenta_repeticiones(*matriz,f,c,ori): rutina para contar el n�mero de
@;	repeticiones del elemento situado en la posici�n (f,c) de la matriz, 
@;	visitando las siguientes posiciones seg�n indique el par�metro de
@;	orientaci�n 'ori'.
@;	Restricciones:
@;		* s�lo se tendr�n en cuenta los 3 bits de menor peso de los c�digos
@;			almacenados en las posiciones de la matriz, de modo que se ignorar�n
@;			las marcas de gelatina (+8, +16)
@;		* la primera posici�n tambi�n se tiene en cuenta, de modo que el n�mero
@;			m�nimo de repeticiones ser� 1, es decir, el propio elemento de la
@;			posici�n inicial
@;	Par�metros:
@;		R0 = direcci�n base de la matriz
@;		R1 = fila 'f'
@;		R2 = columna 'c'
@;		R3 = orientaci�n 'ori' (0 -> Este, 1 -> Sur, 2 -> Oeste, 3 -> Norte)
@;	Resultado:
@;		R0 = n�mero de repeticiones detectadas (m�nimo 1)
	.global cuenta_repeticiones
cuenta_repeticiones:
		push {r1-r8,r12,lr}

		cmp r3, #2         @;                                            +-------->
		rsblo r6, r3, #1   @; Transformem la direccio monodimensional    |       +x
		movlo r7, r3       @;     en un vector de dues dimensions        |
		subhs r6, r3, #3   @;            (x, y) = (r6, r7)               V -y
		rsbhs r7, r3, #2   @; 

		mov r8, #COLUMNS             @; Guardem la constant en registre per a poder multiplicar
		mla r4, r8, r1, r2           @; Creem l'adreça local del primer element (f*COLUMNS + c)
		ldr r12, [r4, r0]            @; Guardem la codificacio complerta del primer element
		and r12, #ELEMENT_MASK       @; Seleccionem els bits tipus d'element
		mov r4, r12                  @; Guardem en r4 el tipus d'element que estem buscant
		mov r5, #0                   @; Posem el contador a 0

	.L_contaSeguent:
		cmp r4, r12     @; Comparem els tipus d'elements
		addeq r5, #1    @; Si son del mateix tipus contador++
		bne .L_fiBucle  @; Si no son el mateix hem acabat

		add r1, r7                  @; Calculem la seguent fila a mirar
		add r2, r6                  @; Calculem la seguen columna a mirar
		mla r12, r8, r1, r2         @; Calculem l'adreça local del nou element
		ldr r12, [r12, r0]          @; Calculem l'adreça absoluta del nou element i guardem la seva codificacio
		and r12, #ELEMENT_MASK      @; Seleccionem els seus bits tipus d'element

		cmp r1, #ROWS        @;
		bhs .L_fiBucle       @;
		cmp r1, #0           @;
		blo .L_fiBucle       @;  Comprovem que seguin dins del rang del taulell
		cmp r2, #COLUMNS     @;
		bhs .L_fiBucle       @;
		cmp r2, #0           @;
		blo .L_fiBucle       @;
		b .L_contaSeguent    @;

	.L_fiBucle:
		mov r0, r5

		pop {r1-r8,r12,pc}



@;TAREA 1F;
@; baja_elementos(*matriz): rutina para bajar elementos hacia las posiciones
@;	vac�as, primero en vertical y despu�s en sentido inclinado; cada llamada a
@;	la funci�n s�lo baja elementos una posici�n y devuelve cierto (1) si se ha
@;	realizado alg�n movimiento, o falso (0) si est� todo quieto.
@;	Restricciones:
@;		* para las casillas vac�as de la primera fila se generar�n nuevos
@;			elementos, invocando la rutina 'mod_random' (ver fichero
@;			"candy1_init.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica se ha realizado alg�n movimiento, de modo que puede que
@;				queden movimientos pendientes. 

	.global baja_elementos
baja_elementos:
		push {r4,lr}

		mov r4, r0
		bl baja_verticales
		cmp r0, #0
		bleq baja_laterales

		pop {r4,pc}



@;:::RUTINAS DE SOPORTE:::

 
@; baja_verticales(mat): rutina para bajar elementos hacia las posiciones vac�as
@;	en vertical; cada llamada a la funci�n s�lo baja elementos una posici�n y
@;	devuelve cierto (1) si se ha realizado alg�n movimiento.
@;	Par�metros:
@;		R4 = direcci�n base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado alg�n movimiento.

@; ############################################################
@; ###################  Let Registers be:  ####################
@; ############################################################
@; R0 = matrix;         || R7 = element_type primer 0;
@; R1 = X primer 0;     || R8 = ;
@; R2 = Y primer 0;     || R9 = element_jelly a baixar || var aux generate_top;
@; R3 = punter.x;       || R10 = element_type a baixar;
@; R4 = punter.y;       || R11 = COLUMNS;
@; R5 = Algun moviment?;|| R12 = aux dir calc;
@; R6 = element_jelly primer 0;

baja_verticales:
		push {r1-r12,lr}

		mov r0, r4         @; Adaptem les dades al codi reutilitzat (r0 = dir matrix)
		mov r3, #COLUMNS-1 @; X e [0, COLUMNS-1]
		mov r4, #ROWS      @; Y e [0, ROWS-1]  (després es resta 1, per això val ROWS)
		mov r5, #0         @; Cap moviment de moment
		mov r11, #COLUMNS  @; COLUMNS per fer mla
		b .Lupper_row

	.Lgenerate_top:
		ldrb r8, [r0, r3]     @; Mirem el primer element
		cmp r3, #COLUMNS*ROWS @; Si esta fora de rang
		subhs r3, r9          @; Arreglem el punter X
		bhs .Lnext_column     @; Passem a la seguen columna
		cmp r8, #VOID_TYPE    @; Si es un forat
		addeq r9, #COLUMNS    @; Sumem l'offset
		addeq r3, #COLUMNS    @; El punter apunta a sota
		beq .Lgenerate_top    @; Mira el seguent element
		mov r12, r9           @;     |   Guardem l'offset per després
		sub r3, r9            @; Si no, arregla el punter x

		and r10, r8, #ELEMENT_MASK @;
		cmp r10, #EMPTY_TYPE       @; Si no esta buit
		bne .Lnext_column          @; passar al seguent

		add r9, r3           @; r9 = Y + offset
		push {r0}            @; r8 = gelatina on generarem
		mov r0, #6           @; (com r8 es segur un 0 nomes conte bits gelatina)
		bl mod_random        @; mod_random(6) + 1 = [1, 6] = element_rand
		add r0, #1           @; 
		add r8, r0           @; r8 = gelatina + element_rand
		pop {r0}             @; 
		strb r8, [r0, r9]    @; Guardem el nou element

		push {r0-r4}          @; 
		and r8, #ELEMENT_MASK @;
		mov r0, r8            @; 
		mov r1, #0-1          @; Creando nuevo
		mov r2, r3            @; elemento grafico
		bl crea_elemento      @; _________________
		mov r0, r1            @; 
		mov r1, r2            @; Animando el nuevo
		mov r2, r12, lsr #3   @;    |   *(lsl 3 divide Y entre 8 porque COLUMNS = 8, si esto canvia se deberia modificar)
		bl activa_elemento    @; elemento grafico
		pop {r0-r4}           @; 

		mov r5, #1   @ Guardem constancia del moviment (generar)

	.Lnext_column:
		sub r3, #1        @; X--;
		cmp r3, #0        @; X < 0
		blt .Lend_of_loop @; Acabar després de comprovar l'ultima columna

		mov r4, #ROWS    @; Y e [0, ROWS-1]  (després es resta 1, per això val ROWS)

	.Lupper_row:
		sub r4, #1         @; Y--;
		cmp r4, #1         @; Saltar a la seguent columna
		movlt r9, #0       @; var aux generate_top (r9) = 0
		blt .Lgenerate_top @; despres de la primera fila

		mla r12, r4, r11, r3  @; Guardem la direccio de memoria local
		ldrb r7, [r0, r12]    @; Guardem en r7 l'element
		and r7, #ELEMENT_MASK @; Extraiem el tipus

		cmp r7, #EMPTY_TYPE @; 
		bne .Lupper_row     @; Busquem el primer element 0 (si n'hi ha)

		mov r1, r3          @; Guardem la X del primer 0
		mov r2, r4          @; Guardem la Y del primer 0
		ldrb r6, [r0, r12]  @;    &
		and r6, #JELLY_MASK @; Guardem els bits gelatina

	.Linavalid_element:
		sub r4, #1            @; Volem mirar l'element superior
		cmp r4, #0-1          @; Saltar a la seguent columna si l'element
		moveq r9, #0          @;   |  var aux generate_top (r9) = 0
		beq .Lgenerate_top    @; seguent va despres de la primera fila

		mla r12, r4, r11, r3  @; Guardem la direccio de memoria local
		ldrb r10, [r0, r12]   @; Guardem en r10 l'element

		cmp r10, #VOID_TYPE    @;
		beq .Linavalid_element @;
		and r10, #ELEMENT_MASK @; Si l'element superior esta buit
		cmp r10, #EMPTY_TYPE   @; o es un solid parar i continuar
		addeq r4, #1           @; Si l'element superior es un
		beq .Lupper_row        @; forat mirar mes adalt
		cmp r10, #SOLID_TYPE   @;
		addeq r4, #1           @;
		beq .Lupper_row        @;

		ldrb r9, [r0, r12]    @; 
		and r9, #JELLY_MASK   @; 
		add r6, r10           @; Intercambiem els elements
		strb r9, [r0, r12]    @; respectant les gelatines
		mla r12, r2, r11, r1  @; 
		strb r6, [r0, r12]    @;

		push {r0-r3}       @; 
		mov r0, r1         @; 
		mov r1, r3         @; 
		mov r3, r0         @; Animacio de l'element en caiguda
		mov r0, r4         @; 
		bl activa_elemento @; 
		pop {r0-r3}        @; 

		mov r3, r1      @; Reposem el punter x
		mov r4, r2      @; Reposem el punter y
		mov r5, #1      @; Hem fet moviments
		b .Lupper_row   @; Seguent element
	
	.Lend_of_loop:
		mov r0, r5

		pop {r1-r12,pc}

@; baja_laterales(mat): rutina para bajar elementos hacia las posiciones vac�as
@;	en diagonal; cada llamada a la funci�n s�lo baja elementos una posici�n y
@;	devuelve cierto (1) si se ha realizado alg�n movimiento.
@;	Par�metros:
@;		R4 = direcci�n base de la matriz de juego
@;	Resultado:
@;		R0 = 1 indica que se ha realizado alg�n movimiento. 

@; ############################################################
@; ###################  Let Registers be:  ####################
@; ############################################################
@; R0 = matrix;
@; R1 = X primer 0 (p0);
@; R2 = Y primer 0 (p0);
@; R3 = punter.x;
@; R4 = punter.y;
@; R5 = p0 type -> aux offset calc;
@; R6 = p0.left type -> left offset;
@; R7 = p0.right type -> right offset;
@; R8 = ;
@; R9 = punter && ELEMENT_TYPE;
@; R10 = punter && JELLY_TYPE -> Hi ha moviments?;
@; R11 = COLUMNS;
@; R12 = aux dir calc;

baja_laterales:
		push {r1-r7,r9-r12,lr}

		mov r0, r4        @; Adaptem les dades al codi reutilitzat (r0 = dir matrix)
		mov r1, #COLUMNS  @; r1 = X global e [0, COLUMNS-1] (més tard es resta 1)
		mov r2, #ROWS     @; r2 = Y global e [0, ROWS-1] (més tard es resta 1)
		mov r10, #0       @; r10 = comprova si hi ha hagut moviments
		mov r11, #COLUMNS @; Columns com a registre, per fer calculs mla

	.LforY:
		sub r2, #1 @; Y--;
		cmp r2, #1 @; 
		blo .Lend  @; IF (y < 1) {fi de programa (no cal revisarla fila 0)}

	.LforX:
		sub r1, #1         @; X--;
		cmp r1, #0-1       @; IF (X < 0)
		moveq r1, #COLUMNS @;   |    (reiniciem el comptador X)
		beq .LforY         @; {seguent fila}
	
		mla r12, r2, r11, r1  @; 
		ldrb r5, [r0, r12]    @; Guardem l'element global
		
		and r5, #ELEMENT_MASK @; 
		cmp r5, #EMPTY_TYPE   @; Si no està buit no ens
		bne .LforX            @; interessa (mirem el seguent)

	.Lcheck_left:  @; r5 passa a ser un acumulador per calcular l'offset
		sub r4, r2, #1 @; 
		sub r4, r5     @; Si la seguent fila esta fora
		cmp r4, #0     @; de rang no es podran fer
		blt .LforX     @; moviments, passem al seguent

		sub r3, r1, #1            @; 
		sub r3, r5                @; Si la columna anterior esta
		cmp r3, #0                @; fora de rang, offset esquerra (r6) = 0
		blt .Lprepare_check_right @; (no es un moviment valid, provem l'altre)

		mla r12, r4, r11, r3 @;
		ldrb r6, [r0, r12]   @; Guardem l'element de l'esquerra

		cmp r6, #SOLID_TYPE          @;
		beq .Lprepare_check_right    @; IF (element.esquerre == (0 or 7)) {
		cmp r6, #VOID_TYPE           @;    offset esquerra (r6) = 0 [moviment no valid];
		@;addeq r5, #1               @;    provem a la dreta;}
		@;beq .Lcheck_left           @; } IF (element.esquerre == 15) {
		beq .Lprepare_check_right    @;    acumulador d'offset (r5)++;
		and r6, #ELEMENT_MASK        @;    provem seguent a la esquerra;
		cmp r6, #EMPTY_TYPE          @; }
		beq .Lprepare_check_right    @; es comenta codi per limitar l'alçada

		add r6, r5, #1  @; Calculem l'offset esquerre
		mov r5, #0      @; Reset per calcular l'offset dret
		b .Lcheck_right @; Mirem dreta
	
	.Lprepare_check_right:
		mov r5, #0
		mov r6, #0

	.Lcheck_right:
		sub r4, r2, #1 @;
		sub r4, r5     @; Si la seguent fila esta fora
		cmp r4, #0     @; de rang no es podran fer
		blt .LforX     @; moviments, passem al seguent

		add r3, r1, #1   @; 
		add r3, r5       @;
		cmp r3, #COLUMNS @; Si la columna seguent esta
		movhs r7, #0     @; fora de rang, offset dret (r7) = 0
		bhs .Lchoose     @; (no es un moviment valid, decidim costat)

		mla r12, r4, r11, r3 @;
		ldrb r7, [r0, r12]   @; Guardem l'element de la dreta

		cmp r7, #SOLID_TYPE    @;
		moveq r7, #0           @;
		beq .Lchoose           @; IF (element.dret == (0 or 7)) {
		cmp r7, #VOID_TYPE     @;    offset dret (r7) = 0 [moviment no valid];
		@;addeq r5, #1         @;    decidim costat per fer el canvi;}
		@;beq .Lcheck_right    @; } IF (element.dret == 15) {
		beq .Lchoose           @;    acumulador d'offset (r5)++;
		and r7, #ELEMENT_MASK  @;    provem seguent a la dreta;
		cmp r7, #EMPTY_TYPE    @; }
		moveq r7, #0           @; 
		beq .Lchoose           @;es comenta codi per limitar l'alçada

		add r7, r5, #1 @; Calculem l'offset dret

	.Lchoose:
		add r5, r6, r7 

		cmp r5, #0       @; 
		beq .LforX       @; Si la suma es 0 -> seguent element
		cmp r5, r6       @;      (no hi ha moviments possibles)
		subeq r4, r2, r6 @; 
		subeq r3, r1, r6 @; Si la suma es = offset esquerra
		beq .Lswap       @;   L> nomes ens podem moure a l'esquerra (el punter senyala l'esquerra)
		cmp r5, r7       @; 
		subeq r4, r2, r7 @; Si la suma es = offset dret
		addeq r3, r1, r7 @;   L> nomes ens podem moure a la dreta (el punter senyala la dreta)
		beq .Lswap       @; 

		push {r0}        @; 
		mov r0, #2       @; 
		bl mod_random    @; Si arrivem fins aqui
		cmp r0, #1       @;  L> Cal triar aleatoriament el costat
		pop {r0}         @; 
		subeq r4, r2, r6 @;   0: Dreta
		subeq r3, r1, r6 @;   1: Esquerra
		subne r4, r2, r7 @; 
		addne r3, r1, r7 @; 

	.Lswap:
		mla r12, r4, r11, r3     @; 
		ldrb r9, [r0, r12]       @; Posicio alta:
		and r10, r9, #JELLY_MASK @;   L> = 0 + r10 (gelatina alta)
		and r9, #ELEMENT_MASK    @; 
		strb r10, [r0, r12]      @;  R10 canvia de valor:
		mla r12, r2, r11, r1     @;   (r10 = gelatina alta) -> (r10 = gelatina baixa)
		ldrb r10, [r0, r12]      @; 
		and r10, #JELLY_MASK     @; Posicio baixa:
		add r9, r10              @;   L> = r9 (element alt) + r10 (gelatina baixa)
		strb r9, [r0, r12]       @; 

		push {r0-r3}       @; 
		mov r0, r1         @; 
		mov r1, r3         @; 
		mov r3, r0         @; Animacio de l'element en caiguda
		mov r0, r4         @; 
		bl activa_elemento @; 
		pop {r0-r3}        @; 
		
		mov r10, #1 @; Guardem que em fet movimetns
		b .LforX    @; Seguent element

	.Lend:
		mov r0, r10 @; Indiquem si em fet moviments

		pop {r1-r7,r9-r12,pc}
.end
