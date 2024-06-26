# Функции

## Сборка и запуск

1. Необходимо перейти в корневую директорию и выполнить команду для сборки проекта

```
make
```

2. Исполняемый файл появятся в папке ```bin```

3. Для удаления объектных и исполняемых файлов необходимо выполнить команду

```
make clean
```

## Задания

### Задание 1. Переписать абонентский справочник с использованием функций.

Справочник можно найти в [этом репозитории](https://github.com/EltexEmbeddedC/structures).

### Задание 2. Имеется программа (исходный код которой приводится в [src/main.c](https://github.com/EltexEmbeddedC/functions/blob/main/src/main.c), компилируется с ключами: -fno-stack-protector -no-pie). Необходимо произвести анализ программы с помощью отладчика для выяснения длины массива для ввода пароля и адреса ветки условия проверки корректности ввода пароля, которая выполняется при условии совпадения паролей. Ввести пароль (строку символов) таким образом, чтобы перезаписать адрес возврата на выясненный адрес (есть символы которые нельзя ввести с клавиатуры, поэтому можно использовать перенаправление ввода (<) при запуске программы).

Откроем исполняемый файл в отладчике:

```
gdb password_checker
```

```bash
GNU gdb (Ubuntu 12.1-0ubuntu1~22.04.2) 12.1
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
Type "show copying" and "show warranty" for details.
This GDB was configured as "x86_64-linux-gnu".
Type "show configuration" for configuration details.
For bug reporting instructions, please see:
<https://www.gnu.org/software/gdb/bugs/>.
Find the GDB manual and other documentation resources online at:
    <http://www.gnu.org/software/gdb/documentation/>.

For help, type "help".
Type "apropos word" to search for commands related to "word"...
Reading symbols from password_checker...
```

Поставим точку остановки на функцию ```main```:

```
(gdb) b main
```

```bash
Breakpoint 1 at 0x4011a2: file src/main.c, line 10.
```

Выясним адрес ветки, в которую входит программа в случае успешной проверки пароля. Для этого запустим программу и дизассемблируем функцию ```main```:

```bash
(gdb) r
Starting program: /home/alexey/Projects/Eltex/HW/functions/bin/password_checker 
[Thread debugging using libthread_db enabled]
Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".

Breakpoint 1, main () at src/main.c:10
10	  puts("Enter password:");
```

```
(gdb) disassemble 
Dump of assembler code for function main:
   0x0000000000401196 <+0>:	endbr64 
   0x000000000040119a <+4>:	push   %rbp
   0x000000000040119b <+5>:	mov    %rsp,%rbp
   0x000000000040119e <+8>:	sub    $0x10,%rsp
=> 0x00000000004011a2 <+12>:	lea    0xe5b(%rip),%rax        # 0x402004
   0x00000000004011a9 <+19>:	mov    %rax,%rdi
   0x00000000004011ac <+22>:	call   0x401070 <puts@plt>
   0x00000000004011b1 <+27>:	call   0x4011ee <IsPassOk>
   0x00000000004011b6 <+32>:	mov    %eax,-0x4(%rbp)
   0x00000000004011b9 <+35>:	cmpl   $0x0,-0x4(%rbp)
   0x00000000004011bd <+39>:	jne    0x4011d8 <main+66>
   0x00000000004011bf <+41>:	lea    0xe4e(%rip),%rax        # 0x402014
   0x00000000004011c6 <+48>:	mov    %rax,%rdi
   0x00000000004011c9 <+51>:	call   0x401070 <puts@plt>
   0x00000000004011ce <+56>:	mov    $0x1,%edi
   0x00000000004011d3 <+61>:	call   0x4010a0 <exit@plt>
   0x00000000004011d8 <+66>:	lea    0xe43(%rip),%rax        # 0x402022
   0x00000000004011df <+73>:	mov    %rax,%rdi
   0x00000000004011e2 <+76>:	call   0x401070 <puts@plt>
   0x00000000004011e7 <+81>:	mov    $0x0,%eax
   0x00000000004011ec <+86>:	leave  
   0x00000000004011ed <+87>:	ret    
End of assembler dump.
```

Таким образом, адрес нужной ветки ```0x00000000004011d8```. Войдем отладчиком в функцию ```IsPassOk```, при запросе пароля введем ```abc``` и выведем 32 байта стека, начиная с регистра ```$rsp```:

```c
int IsPassOk(void) {
  char Pass[12];
  gets(Pass);
  return 0 == strcmp(Pass, "test");
}
```

```bash
(gdb) x/32x $rsp
0x7fffffffde20:	0x68	0xdf	0xff	0xff	0x61	0x62	0x63	0x00
0x7fffffffde28:	0x96	0x11	0x40	0x00	0x00	0x00	0x00	0x00
0x7fffffffde30:	0x50	0xde	0xff	0xff	0xff	0x7f	0x00	0x00
0x7fffffffde38:	0xb6	0x11	0x40	0x00	0x00	0x00	0x00	0x00
```

Строка ```abc``` в ASCII представляется как ```\x61\x62\x63```, следовательно, массив ```Pass[12]```, который хранит пароль расположен на адресах ```0x7fffffffde24-0x7fffffffde29```. За ним следует 8 байт сохраненного ```$rbp```, а затем адрес возврата, который и нужно перезаписать:

```0x7fffffffde38:	0xb6	0x11	0x40	0x00	0x00	0x00	0x00	0x00```

Создадим строку, являющуюся конкатенацией строки из 12 байт (чтобы заполнить массив), текущего адреса сохраненного ```$rbp``` и нового адреса возврата ```0x00000000004011d8```. 

Запишем эту строку в ```password.bin``` выполнением скрипта [create_output.sh](https://github.com/EltexEmbeddedC/functions/blob/main/create_output.sh).

Теперь запустим программу, перенаправив поток ввода в ```password.bin```:

```bash
alexey@alexey-HVY-WXX9:~/Projects/Eltex/HW/functions/bin$ ./password_checker < password.bin 
Enter password:
Access granted!
```

![Результат](/result.png)

В результате чего программа выводит строку ```Access granted!```.
