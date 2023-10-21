format MZ
entry code_segment:main
stack 400h
;---------------------------
segment data_seg

file_name db "SamsonovEM.txt$"

buff db 2 dup(?) 

;---------------------------
segment code_segment

main:
    mov ax, data_seg                        ;Записываем в DS сегмент с данными
    mov ds, ax
    mov dx, file_name

    call create_and_open_file               ;Создаём и открываем файл
    mov bx, ax                              ;Кладём логический номер файла в BX. Нужно для вывода
    
    mov ax, data_seg                        ;Записываем в DS сегмент с данными
    mov ds, ax

    mov ax, 0xb800                          ;Записываем сегмент для вывода дампа
    mov es, ax
    mov di, 512                             ;Записываем смещение для вывода дампа

    mov cx, 16                              ;Цикл вывода дампа в файл
    row_run:
        push cx
        mov cx, 16
        column_run:
            call get_ahal_byte
            call write_block_dump
            call write_space
            loop column_run
        call write_endl
        pop cx
        loop row_run
    
    jmp end_running

;Записывает в AX байт из ES:DI, увеличивает DI на 1.
;В AH код первого символа в AL код второго
get_ahal_byte:
    push bx

    xor ax, ax                              ;0 в АХ                             
    mov al, byte[es:di]                     ;Прочитали память в AX
    push ax                                 ;Сохранили данные на вывод в стек

    shr al, 4                               ;Смещаем значение вправо, чтобы оставить один символ
    and al, 0xf                             ;Через маску обнуляем всё остальное                    
    cmp al, 0x9                             ;Проверяем цифра это или буква
    ja symb_ah
    ;---Блок с цифрой---                    ;Запись ASCII кода цифры
        add al, 0x30
        mov ah, al
        jmp part_two
    ;-------------------

    symb_ah:                                ;Запись ASCII кода буквы
        add al, 0x37
        mov ah, al

    part_two:
    mov bh, ah                              ;Сохраняем найденный код в BH
    pop ax

    and al, 0xf                             ;Оставляем крайний символ
    cmp al, 0x9                             ;Проверяем цифра это или буква
    ja symb_al
    ;---Блок с цифрой---                    ;Запись ASCII кода цифры
        add al, 0x30
        jmp part_three
    ;-------------------

    symb_al:                                ;Запись ASCII кода символа
        add al, 0x37

    part_three:                             ;Настройка значений
    add di, 1
    mov ah, bh
    pop bx
    ret

;В AH и AL должны лежать два символа на вывод
write_block_dump:                           ;В BX должен лежать логический номер файла, в СХ кол-во байт на запись - для записи в файл
    pusha
    
    push ax                                 ;Запомнили значение
    mov byte[ds:buff], ah                   ;Записываем в буфер значение на вывод в файл
    pop ax                                  ;Восстановили значение
    mov byte[ds:buff+1], al                 ;Записываем в буфер значение на вывод в файл
    mov cx, 2                               ;Указываем, что выведем 1 символ
    mov dx, buff                            ;Для работы функции прерывания, указываем смещение. Строка вывода: DS:DX
    mov ah, 0x40                            ;Функция записи в файл
    int 0x21                                ;Вызываем прерывание

    popa
    ret

write_space:                                ;Блок по выводу пробела в файл
    pusha

    mov byte[ds:buff], " "              
    mov cx, 1
    mov dx, buff
    mov ah, 0x40
    int 0x21

    popa
    ret

 write_endl:                                ;Блок по выводу конца строки в файл
    pusha

    mov byte[ds:buff], 0xA
    mov cx, 1
    mov dx, buff
    mov ah, 0x40
    int 0x21

    popa
    ret   

create_and_open_file:                       ;В ds:dx имя файла. В AX запишется логический номер файла
    push cx

    xor cx,cx                               ;Обнуляем СХ, чтобы создался обычный файл(без флагов) 
    mov ah, 0x3C                            ;Функция создания файла
    int 0x21                                ;Вызываем прерывание

    pop cx
    
    ret

 end_running:
    xor ax, ax
    int 0x16
    mov ax, 0x4C00
    int 0x21   