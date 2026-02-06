; ============================================================================
; PROGRAMA: Búsqueda de Máximo y Mínimo en Arreglo
; ARQUITECTURA: x64
; ENSAMBLADOR: MASM (ml64.exe)
; ============================================================================
; ALGORITMO:
;   1. Inicializar max y min con primer elemento
;   2. Recorrer arreglo desde segundo elemento
;   3. Comparar cada elemento con max y min actuales
;   4. Actualizar max si elemento > max
;   5. Actualizar min si elemento < min
;   6. Repetir hasta fin del arreglo
; ============================================================================

.data
    ; Arreglo de enteros (32 bits cada uno)
    arreglo DWORD 45, 12, 89, 3, 67, 23, 91, 8, 56, 34
    longitud DWORD 10                       ; Número de elementos
    
    ; Variables para resultados
    maximo DWORD ?                          ; Almacenará el valor máximo
    minimo DWORD ?                          ; Almacenará el valor mínimo
    
    ; Mensajes para salida
    msgInicio BYTE "Buscando maximo y minimo...", 0Dh, 0Ah, 0
    msgMax BYTE "Valor maximo: ", 0
    msgMin BYTE "Valor minimo: ", 0
    msgNewline BYTE 0Dh, 0Ah, 0
    fmtInt BYTE "%d", 0                     ; Formato para enteros

.code
    ; Declaraciones externas para funciones de C runtime
    extern printf: PROC
    extern ExitProcess: PROC

main PROC
    ; ========================================================================
    ; PRÓLOGO: Preparar stack frame (alineación x64 ABI)
    ; ========================================================================
    push rbp                                ; Guardar base pointer
    mov rbp, rsp                            ; Establecer nuevo frame (opcional, útil debug)
    
    ; Guardar registros no volátiles
    push rsi
    push rbx
    push rdi
    
    ; ALINEACIÓN DE STACK Y SHADOW SPACE
    ; Stack actual (desde entrada):
    ; RetAddr(8) + RBP(8) + RSI(8) + RBX(8) + RDI(8) = 40 bytes.
    ; Necesitamos alineación de 16 bytes. 40 no es múltiplo de 16.
    ; Necesitamos reservar Shadow Space (32 bytes) min.
    ; sub rsp, 28h (40 bytes) -> Total 80 bytes (múltiplo de 16). OK.
    
    sub rsp, 28h                            ; Reservar shadow space (32) + padding (8)
    
    ; ========================================================================
    ; FASE 1: INICIALIZACIÓN
    ; CPU: Carga valores desde memoria RAM a registros
    ; ========================================================================
    
    lea rsi, arreglo                        ; RSI = dirección base del arreglo
                                            ; CPU: Carga dirección efectiva
                                            
    mov ecx, longitud                       ; ECX = contador de elementos
                                            ; CPU: MOV copia desde [longitud] a ECX
                                            
    mov eax, DWORD PTR [rsi]                ; EAX = primer elemento (inicial max)
                                            ; CPU: Acceso a memoria, bus de datos
                                            ; transfiere 4 bytes a registro
                                            
    mov maximo, eax                         ; Guardar en variable maximo
    mov minimo, eax                         ; Guardar en variable minimo
                                            ; CPU: Escritura a memoria RAM
    
    mov ebx, eax                            ; EBX = max actual (registro)
    mov edx, eax                            ; EDX = min actual (registro)
                                            ; Trabajar en registros es más rápido
    
    dec ecx                                 ; Decrementar contador (ya procesamos 1)
                                            ; CPU: ALU ejecuta resta
                                            ; FLAGS: Actualiza ZF, SF, OF
                                            
    add rsi, 4                              ; Avanzar puntero al siguiente elemento
                                            ; CPU: Aritmética de punteros
                                            ; +4 porque cada DWORD = 4 bytes
    
    ; ========================================================================
    ; FASE 2: BUCLE PRINCIPAL - PARTE CRÍTICA DEL PROGRAMA
    ; CPU: Ciclo fetch-decode-execute repetitivo
    ; ========================================================================
    
bucle_comparacion:
    cmp ecx, 0                              ; Comparar contador con 0
                                            ; CPU: ALU ejecuta resta (ECX - 0)
                                            ; FLAGS: Actualiza ZF (Zero Flag)
                                            ; No modifica ECX, solo FLAGS
                                            
    je fin_bucle                            ; Si ZF=1, saltar a fin_bucle
                                            ; CPU: Evalúa condición en FLAGS
                                            ; Si salta: PC = dirección de fin_bucle
                                            ; Si no: PC = siguiente instrucción
    
    ; --------------------------------------------------------------------
    ; Cargar elemento actual
    ; --------------------------------------------------------------------
    mov eax, DWORD PTR [rsi]                ; EAX = elemento actual del arreglo
                                            ; CPU: 
                                            ; 1. Decodifica [RSI] como dirección
                                            ; 2. Envía dirección por bus de direcciones
                                            ; 3. RAM responde con 4 bytes
                                            ; 4. Bus de datos transfiere a EAX
    
    ; --------------------------------------------------------------------
    ; Comparación con MÁXIMO
    ; --------------------------------------------------------------------
    cmp eax, ebx                            ; Comparar actual vs max
                                            ; CPU: ALU ejecuta (EAX - EBX)
                                            ; FLAGS actualizados:
                                            ;   ZF = 1 si iguales
                                            ;   SF = 1 si resultado negativo
                                            ;   CF = 1 si hay acarreo
                                            
    jle no_es_maximo                        ; Si EAX <= EBX, saltar
                                            ; CPU: Evalúa (ZF=1 OR SF≠OF)
                                            ; Jump if Less or Equal
                                            
    mov ebx, eax                            ; Actualizar máximo
                                            ; CPU: Transferencia registro-registro
                                            ; Ciclo de reloj único, muy rápido
                                            
no_es_maximo:
    
    ; --------------------------------------------------------------------
    ; Comparación con MÍNIMO
    ; --------------------------------------------------------------------
    cmp eax, edx                            ; Comparar actual vs min
                                            ; CPU: ALU ejecuta (EAX - EDX)
                                            ; FLAGS: Mismo proceso que antes
                                            
    jge no_es_minimo                        ; Si EAX >= EDX, saltar
                                            ; CPU: Evalúa (ZF=1 OR SF=OF)
                                            ; Jump if Greater or Equal
                                            
    mov edx, eax                            ; Actualizar mínimo
                                            ; CPU: Transferencia registro-registro
                                            
no_es_minimo:
    
    ; --------------------------------------------------------------------
    ; Avanzar al siguiente elemento
    ; --------------------------------------------------------------------
    add rsi, 4                              ; Incrementar puntero
                                            ; CPU: ALU suma 4 a RSI
                                            ; Apunta al siguiente DWORD
                                            
    dec ecx                                 ; Decrementar contador
                                            ; CPU: ALU resta 1 de ECX
                                            ; FLAGS: Actualiza ZF cuando ECX=0
                                            
    jmp bucle_comparacion                   ; Salto incondicional al inicio
                                            ; CPU: PC = dirección de bucle_comparacion
                                            ; Pipeline puede predecir este salto
    
    ; ========================================================================
    ; FASE 3: FINALIZACIÓN
    ; ========================================================================
    
fin_bucle:
    ; Guardar resultados finales en memoria
    mov maximo, ebx                         ; Escribir max a memoria
    mov minimo, edx                         ; Escribir min a memoria
                                            ; CPU: Bus de datos → RAM
    
    ; ========================================================================
    ; FASE 4: MOSTRAR RESULTADOS (usando printf de C runtime)
    ; ========================================================================
    
    ; Mostrar mensaje de inicio
    lea rcx, msgInicio                      ; Primer parámetro (x64 calling convention)
    call printf                             ; Llamar a printf
    
    ; Mostrar máximo
    lea rcx, msgMax                         ; Mensaje "Valor maximo: "
    call printf
    
    mov ecx, maximo                         ; Cargar desde memoria (seguro tras printf)
    call imprimir_numero
    
    lea rcx, msgNewline
    call printf
    
    ; Mostrar mínimo
    lea rcx, msgMin                         ; Mensaje "Valor minimo: "
    call printf
    
    mov ecx, minimo                         ; Cargar desde memoria (Vital: EDX fue sobreescrito por printf)
    call imprimir_numero
    
    lea rcx, msgNewline
    call printf
    
    ; ========================================================================
    ; EPÍLOGO: Restaurar stack y salir
    ; ========================================================================
    add rsp, 28h                            ; Liberar shadow space + padding
    
    pop rdi
    pop rbx
    pop rsi                                 ; Restaurar registros no volátiles
    pop rbp                                 ; Restaurar base pointer
    
    xor ecx, ecx                            ; ECX = 0 (código de salida)
    call ExitProcess                        ; Terminar proceso
    
main ENDP

; ============================================================================
; PROCEDIMIENTO AUXILIAR: Imprimir número en decimal
; ============================================================================
imprimir_numero PROC
    ; Parámetro: ECX = número a imprimir
    
    push rbp
    mov rbp, rsp
    sub rsp, 20h                            ; Shadow space para la llamada a printf (32 bytes)
    
    ; Configurar argumentos para printf(fmt, valor)
    ; RCX = Puntero al string de formato
    ; RDX = Valor entero
    
    mov edx, ecx                            ; Mover el valor a imprimir a RDX (2º argumento)
    lea rcx, fmtInt                         ; Cargar dirección del formato "%d" a RCX (1er argumento)
    
    call printf                             ; Llamar a función de C
    
    add rsp, 20h                            ; Limpiar shadow space
    pop rbp
    ret
imprimir_numero ENDP

END