@;=                                                          	     	=
@;=== candy1_init.s: rutinas para inicializar la matriz de juego	  ===
@;=                                                           	    	=
@;=== Programador tarea 1A: oriol.algar@estudiants.urv.cat				  ===
@;=== Programador tarea 1B: oriol.algar@estudiants.urv.cat				  ===
@;=== Programador tarea 2Ia: oriol.algar@estudiants.urv.cat               ===
@;=                                                       	        	=


.include "../include/candy1_incl.i"

@;valors inmediats de m�scares i de m�xim d'iteracions
MASK_ESP_BUIT = 0x07
MASK_GEL_SIMP = 0x08
MASK_GEL_DOBL= 0x10
MAX_ITERACIONS = 500

@;-- .bss. variables (globales) no inicializadas ---
.bss
		.align 2
@; matrices de recombinaci�n: matrices de soporte para generar una nueva matriz
@;	de juego recombinando los elementos de la matriz original.
	mat_recomb1:	.space ROWS*COLUMNS
	mat_recomb2:	.space ROWS*COLUMNS
	
	


@;-- .text. c�digo de las rutinas ---
.text	
		.align 2
		.arm



@;TAREA 1A;
@; inicializa_matriz(*matriz, num_mapa): rutina para inicializar la matriz de
@;	juego, primero cargando el mapa de configuraci�n indicado por par�metro (a
@;	obtener de la variable global 'mapas'), y despu�s cargando las posiciones
@;	libres (valor 0) o las posiciones de gelatina (valores 8 o 16) con valores
@;	aleatorios entre 1 y 6 (+8 o +16, para gelatinas)
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocar� la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocar� la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;		R1 = n�mero de mapa de configuraci�n
@;	�ndex de registres:-------------------
@;		R1 = de nombre de mapa de configuraci� es passa a fila de la casella que volem tractar a cuenta_repeticiones
@;		R2 = columna de la casella actual
@;		R3 = direcci� per a cuenta_repeticiones
@;		R4 = valor de la casella actual
@;		R5 = �ndex per ananr canviant de casella
@;		R6 = dimensi� de la matriu
@;		R7 = direcci� del mapa de configuraci� dessitjat
@; 		R8 = backup direcci� base de la matriu de joc
@; 		R9 = fila de la casella actual
@;		R10 = columna de la casella actual
	.global inicializa_matriz
inicializa_matriz:
		push {r0-r10, lr}		@;guardar registros utilizados

		mov r8, r0				@;fem backup de la direcci� base de la matriu
		mov r6, #ROWS*COLUMNS	@;dimensi� de la matriu
		mul r6, r1				@;multipliquem la dimensi� de una matriu per el n�mero de mapa per poder accedir al que vol el usuari
		ldr r7, =mapas
		add r7, r6				@;sumem la direcci� base de la matriu que cont� tots els mapes a la casella on comen�a el mapa indicat
		mov r5, #0				@;inicialitzem l'index
		mov r9, #0				@;inicialitzem files
	
	.Lwhilefila:
		mov r10, #0				@;inicialitzem columnes
	
	.Lwhilecolumn:
		ldrb r4, [r7, r5]		@;carreguem el valor de la casella del mapa que va indicant l'index en r5 a r4
	
	.Lifespaivuit:
		tst r4, #MASK_ESP_BUIT	@;fem un and amb la mascara i nom�s es guarda el flagz
		beq .Lbuclerandom		@;si els bits 0, 1 i 2 de r4 son igual a 0 el flagz es posar� a 1 i saltar� al buclerandom
		strb r4, [r8, r5]		@;guardem el valor a la matriu base del joc
		b .Lendifespaivuit		@;anem al final perque no salti als bucles

	
	@;bucle per posar un nombre random en la casella corresponent
	.Lbuclerandom:
		ldrb r4, [r7, r5]
		mov r0, #6				@;pasem el rang a r0 perque el passi a la ruitna mod_random
		bl mod_random
		add r0, #1				@;sumem 1 per asegurarnos que no dona 0
		add r4, r0				@;sumem el valor de la casella del mapa amb el num aleatori		
		mov r0, r8				@;recuperem la direcci� base per pasarli al cuenta repeticiones
		mov r1, r9				@;passem la fila de la casella actual
		mov r2, r10				@;passem la columna de la casella actual
		mov r3, #2				@;indiquem la direcci� oest
		strb r4, [r0, r5]		@;guardem el resultat a la matriu base del joc
		bl cuenta_repeticiones
		cmp r0, #3				@;comparem que el num de repeticions no sigui mes gran que 3
		bge .Lbuclerandom
		@;ara mirem en la direcci� nord
		mov r0, r8				@;tornem a recuperar la direcci� base 
		mov r1, r9				@;passem la fila de la casella actual
		mov r2, r10				@;passem la columna de la casella actual
		mov r3, #3				@;li pasem la direcci� nord
		bl cuenta_repeticiones
		cmp r0, #3				@;comparem que el num de repeticions no sigui mes gran que 3
		bge .Lbuclerandom
	
	.Lendifespaivuit:
		add r5, #1				@;comparem l'�ndex amb el nombre total de caselles de la matriu per saber si hem arribat al final
		add r10, #1
		cmp r10, #COLUMNS		@;comparem si ja hem tractat la �ltima columna
		blo .Lwhilecolumn
		@;si ja hem arribat hem de canviar de fila
		add r9, #1				@;cambiem de fila
		cmp r9, #ROWS			@;comparem l'�ndex de files per saber si ja hem acabat amb la �ltima
		blo .Lwhilefila
		
		pop {r0-r10, pc}		 @;recuperar registros y volver



@;TAREA 1B;
@; recombina_elementos(*matriz): rutina para generar una nueva matriz de juego
@;	mediante la reubicaci�n de los elementos de la matriz original, para crear
@;	nuevas jugadas.
@;	Inicialmente se copiar� la matriz original en 'mat_recomb1', para luego ir
@;	escogiendo elementos de forma aleatoria y colocandolos en 'mat_recomb2',
@;	conservando las marcas de gelatina.
@;	Restricciones:
@;		* para obtener elementos de forma aleatoria se invocar� la rutina
@;			'mod_random'
@;		* para evitar generar secuencias se invocar� la rutina
@;			'cuenta_repeticiones' (ver fichero "candy1_move.s")
@;		* para determinar si existen combinaciones en la nueva matriz, se
@;			invocar� la rutina 'hay_combinacion' (ver fichero "candy1_comb.s")
@;		* se supondr� que siempre existir� una recombinaci�n sin secuencias y
@;			con combinaciones
@;	Par�metros:
@;		R0 = direcci�n base de la matriz de juego
@;	�ndex de registres:-------------------
@;		R1 = �ndex de files
@;		R2 = �ndex de columnes
@;		R3 = valor de casella corresponent
@;		R4 = backup direcci� base de la matriu de joc
@;		R5 = direcci� base de la primera matriu de recombinaci�
@;		R6 = direcci� base de la segona matriu de recombinaci�
@;		R7 = �ndex per rec�rrer la matriu
@; 		R8 = caselles totals de la taula/m�xim d'iteracions 
@; 		R9 = resultat and/backup del valor de mat_recomb2
@;		R10 = valor de la casella de mat_recomb1
@; 		R11 = valor de la casella de mat_recomb2
@;		R12 = backup direcci� aleatoria de mat_recomb1
	
	.global recombina_elementos
recombina_elementos:
		push {r0-r12, lr}
	
		
		mov r4, r0 						@;backup de la direcci� base de la matriu
	.Linici:							@;la etiqueta la possem aquí per asegurarnos de conservar sempre la matriu de joc
		ldr r5, =mat_recomb1 			@;carreguem la direcci� de mem�ria de la primera matriu de recombinaci�
		ldr r6, =mat_recomb2			@;carreguem la direcci� de mem�ria de la segona matriu de recombinaci�
	
		mov r8, #ROWS*COLUMNS			@;multipliquem files per columnes per guardar el nombre total de caselles 
		mov r7, #0						@;inicialitzem l'index
	
	.Ltractar_elem_mat1:
		ldrb r3, [r4, r7]				@;carreguem el valor de la casella corresponent
		and r9, r3, #MASK_GEL_SIMP		@;mirem que nomes el bit 4 estigui a 1
		cmp r9, #MASK_GEL_SIMP			@;quan sigui gelatina simple
		beq .Les_gelatina_mat1
		and r9, r3, #MASK_GEL_DOBL		@;mirem que nomes el bit 5 estigui a 1
		cmp r9, #MASK_GEL_DOBL
		beq .Les_gelatina_mat1
		and	r9, r3, #MASK_ESP_BUIT		@;and amb la m�scara i el resultat es guarda en r9
		cmp r9, #MASK_ESP_BUIT			@;si el resultat dona que es igual aix� vol dir que es bloc i s'ha de possar a 0
		bne .Lend_tractar_mat1		
		mov r3, #0						
		b .Lend_tractar_mat1
	
	.Les_gelatina_mat1:
		and	r9, r3, #MASK_ESP_BUIT		@;and amb la m�scara i el resultat es guarda en r9
		cmp r9, #MASK_ESP_BUIT			@;si els bits 0, 1 i 2 no son tots igual a 1 
		moveq r3, #0					@;amb els 2 cmp que hem utilitzat hem tret que es el valor 15 llavors el movem a 0
		tst r3, #MASK_ESP_BUIT			@;mirem que els bits 0, 1 i 2 estiguin tots a 0
		moveq r3, #0					@;si no es el cas acaba de tractar l'element
		cmp r3, #0						@;comparem per si es el cas que no shagi cumplit la condicio no salti al final
		beq .Lend_tractar_mat1
		mov r3, r9						@;com a r9 tenim el resultat de l'and amb els ultims 3 bits el guardem a la matriu
		
	.Lend_tractar_mat1:
		strb r3, [r5, r7]				@;guardem el valor de la casella en mat_recomb1
		add r7, #1
		cmp r7, r8						@;mirem que l'�ndex no es passi de la extensi�
		blo .Ltractar_elem_mat1			@;si no es el cas tornem al bucle
		mov r7, #0
	
	.Ltractar_elem_mat2:
		ldrb r3, [r4, r7]				@;carreguem el valor de la casella corresponent
		and r9, r3, #MASK_GEL_SIMP		@;mirem que nomes el bit 4 estigui a 1
		cmp r9, #MASK_GEL_SIMP
		beq .LGel_simple
		and r9, r3, #MASK_GEL_DOBL		@;mirem que nomes el bit 5 estigui a 1
		cmp r9, #MASK_GEL_DOBL
		beq .LGel_doble
		and	r9, r3, #MASK_ESP_BUIT		@;and amb la m�scara i el resultat es guarda en r9
		cmp r9, #MASK_ESP_BUIT			@;si els bits 0, 1 i 2 no son tots igual a 1 
		beq .Lend_tractar_mat2			@;quan els tres ultims bits estiguin a 1 salta
		tst r3, #MASK_ESP_BUIT			@;mirem que els bits 0, 1 i 2 estiguin tots a 0
		beq .Lend_tractar_mat2			@;si no es el cas acaba de tractar l'element
		mov r3, #0
		b .Lend_tractar_mat2
	
	.LGel_simple:
		and	r9, r3, #MASK_ESP_BUIT		@;en aquest cas es gelatina simple pero pot ser tamb� buit, per aix� ho comprovem
		cmp r9, #MASK_ESP_BUIT					
		beq .Lend_tractar_mat2				
		mov r3, #MASK_GEL_SIMP			@;si es una casella amb gelatina movem el codi basic de la gelatina al registre	
		b .Lend_tractar_mat2
	
	.LGel_doble:
		mov r3, #MASK_GEL_DOBL			@;movem en r3 el codi basic de la gelatina doble
		b .Lend_tractar_mat2
	
	.Lend_tractar_mat2:
		strb r3, [r6, r7]				@;guardem el contingut de r3 dintre de mat_recomb2 en la posici� que indica l'index
		add r7, #1
		cmp r7, r8
		blo .Ltractar_elem_mat2
	
		mov r8, #0
	.Linicirecomb:
		
		mov r7, #0						@;inicialitzem l'index que indica la posicio
		mov r1, #0						@;inicialitzem l'index de files
	.Lbucle_fila:
		mov r2, #0						@;inicialitzem l'index de columnes
	.Lbucle_col:	
		
		ldrb r3, [r4, r7]
		tst r3, #MASK_ESP_BUIT			@;si la posici� te els tres ultims bits a 0 passem a la seg�ent posicio
		beq .Lfi_tractament
		and r9, r3, #MASK_ESP_BUIT		@;si la posici� te els tres ultims bits a 1 (bloc solid o buit) passem a la seg�ent posici�
		cmp r9, #MASK_ESP_BUIT
		beq .Lfi_tractament
		ldrb r11, [r6, r7]				@;carreguem valor de mat_recomb2
		and r9, r11, #MASK_ESP_BUIT		@;si a mat_recomb2 trobem un bloc solid o buit no cal tractar
		cmp r9, #MASK_ESP_BUIT
		beq .Lfi_tractament
		mov r9, r11						@;fem backup del valor de mat_recomb2
		mov r3, #0
	.Lhay_secuencia:	
		
		cmp r8, #MAX_ITERACIONS			@;amb les iteracions evitem el bucle infinit ja que si supera el maxim torna a començar
		bhi .Linici
		add r8, #1
		mov r11, r9						@;retornem el valor original de la casella a r11 per evitar que es vagi suman
		mov r0, #ROWS*COLUMNS			@;passem rang ROWSxCOLUMNS per a que ens doni una posicio aleatoria de la matriu
		bl mod_random
		mov r12, r0						@;guardem la posici� de la casella per guardar un 0 despres
		ldrb r10, [r5, r0]				@;carreguem valor de mat_recomb1
		cmp r10, #0						@;mirem que el valor carregat de mat_recomb1 no sigui 0
		beq .Lhay_secuencia
		add r11, r10					@;sumem el coid base de mat_recomb1 al codi de gelatina de mat_recomb2				
		strb r11, [r6, r7]				@;guardem la suma a la posici� corresponent de mat_recomb2
		mov r0, r6
		mov r3, #2
		bl cuenta_repeticiones			@;comprovem si hi ha secu�ncia en la direcci� oest
		cmp r0, #3
		bhs .Lhay_secuencia				@;si hi ha secuencia torna a repetir el proc�s
		mov r0, r6
		mov r3, #3
		bl cuenta_repeticiones			@;comprovem si hi ha secu�ncia en la direcci� nord
		cmp r0, #3
		bhs .Lhay_secuencia
		mov r10, #0						@;com hem utilitzat ja aquesta casella en mat_recomb1 posem un 0 perque no la torni a tractar
		strb r10, [r5, r12]
		
	@;FASE 2Ia ACTIVAR ELS SPRITES
		mov r5, r1 						@;backup fila
		mov r6, r2						@;backup columna actual
		mov r2, r1						@; fila actual a r0
		mov r3, r6						@;columna actual a r1
		mov r0, #0  					@;inicialitzem r2 per la divisió
	.Lwhiledivision: 					@;divisió (POSICIÓ DESTÍ/#COLUMNS)=FILA DESTÍ (residu:COLUMNA DESTÍ)
	
		cmp r12, #COLUMNS 				@;va restant columns a la posició destí fins que aquesta sigui menor que columns
		blo .Ldivisioacabada
		sub r12, #COLUMNS
		add r0, #1 						@;si resta columns a la posició incrementem el registre de la fila
		b .Lwhiledivision
	
	.Ldivisioacabada:
		
		mov r1, r12 					@;en r12 queda el residu que es la columna destí i li passem a r3
		bl activa_elemento
		mov r1, r5 						@;recuperem els backups
		mov r2, r6
		
		ldr r5, =mat_recomb1 			@;recuperem la direcci� de mem�ria de la primera matriu de recombinaci�
		ldr r6, =mat_recomb2			@;recuperem la direcci� de mem�ria de la segona matriu de recombinaci�
	@;FI FASE 2Ia
	.Lfi_tractament:	
		
		add r7, #1
		add r2, #1						@;augmentem l'index de columnes
		cmp r2, #COLUMNS				@;mirem si hem arribat al final de les columnes
		blo .Lbucle_col					@;si es el cas entrem al bucle 
		add r1, #1						@;augmentem l'index de les files
		cmp r1, #ROWS					@;mirem si hem arribat a la ultima fila
		blo .Lbucle_fila				@;si es el cas entrem al bucle
		
		mov r7, #0
		mov r9, #ROWS*COLUMNS
	
		mov r0, r6 						@;carreguem mat_recomb2
		bl hay_combinacion 				@;en el cas que recombini i no hagi creat cap combinacio comença de nou
		cmp r0, #1
		bne .Linici
	
	
	.Lcopiarmat:
		ldrb r3, [r6, r7]				@;carreguem el valor de la casella actual de mat_recomb2
		strb r3, [r4, r7]				@;copiem el valor actual a la matriu de joc
		
		add r7, #1
		cmp r7, r9
		blo .Lcopiarmat
	
		pop {r0-r12, pc}
		


@;:::RUTINAS DE SOPORTE:::



@; mod_random(n): rutina para obtener un n�mero aleatorio entre 0 y n-1,
@;	utilizando la rutina 'random'
@;	Restricciones:
@;		* el par�metro 'n' tiene que ser un valor entre 2 y 255, de otro modo,
@;		  la rutina lo ajustar� autom�ticamente a estos valores m�nimo y m�ximo
@;	Par�metros:
@;		R0 = el rango del n�mero aleatorio (n)
@;	Resultado:
@;		R0 = el n�mero aleatorio dentro del rango especificado (0..n-1)
	.global mod_random
mod_random:
		push {r1-r4, lr}
		
		cmp r0, #2				@;compara el rango de entrada con el m�nimo
		bge .Lmodran_cont
		mov r0, #2				@;si menor, fija el rango m�nimo
	.Lmodran_cont:
		and r0, #0xff			@;filtra los 8 bits de menos peso
		sub r2, r0, #1			@;R2 = R0-1 (n�mero m�s alto permitido)
		mov r3, #1				@;R3 = m�scara de bits
	.Lmodran_forbits:
		cmp r3, r2				@;genera una m�scara superior al rango requerido
		bhs .Lmodran_loop
		mov r3, r3, lsl #1
		orr r3, #1				@;inyecta otro bit
		b .Lmodran_forbits
		
	.Lmodran_loop:
		bl random				@;R0 = n�mero aleatorio de 32 bits
		and r4, r0, r3			@;filtra los bits de menos peso seg�n m�scara
		cmp r4, r2				@;si resultado superior al permitido,
		bhi .Lmodran_loop		@; repite el proceso
		mov r0, r4				@; R0 devuelve n�mero aleatorio restringido a rango
		
		pop {r1-r4, pc}



@; random(): rutina para obtener un n�mero aleatorio de 32 bits, a partir de
@;	otro valor aleatorio almacenado en la variable global 'seed32' (declarada
@;	externamente)
@;	Restricciones:
@;		* el valor anterior de 'seed32' no puede ser 0
@;	Resultado:
@;		R0 = el nuevo valor aleatorio (tambi�n se almacena en 'seed32')
random:
	push {r1-r5, lr}
		
	ldr r0, =seed32				@;R0 = direcci�n de la variable 'seed32'
	ldr r1, [r0]				@;R1 = valor actual de 'seed32'
	ldr r2, =0x0019660D
	ldr r3, =0x3C6EF35F
	umull r4, r5, r1, r2
	add r4, r3					@;R5:R4 = nuevo valor aleatorio (64 bits)
	str r4, [r0]				@;guarda los 32 bits bajos en 'seed32'
	mov r0, r5					@;devuelve los 32 bits altos como resultado
		
	pop {r1-r5, pc}	



.end
