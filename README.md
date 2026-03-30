# showme(printf)
Это учебный проект - реализация `printf()` из `cstdlib`, написанная на `NASM`.
- Целевой ABI call - `System V AMD64 ABI`
- Поддерживается `ASLR` (сборка с флагом Position Independent Executable)

В силу ограниченности времени курса, был выбран ограниченный набор спецификаторов:
| Спецификатор | Описание |
|--------------|----------|
| `%%` | Вывод зарезервированного символа `%` в консоль (экранирование) |
| `%b` | Вывод бинарного представления 32х битного значения в консоль |
| `%c` | Вывод ASCII символа в консоль |
| `%d` | Вывод 32х битного знакового десятичного числа в консоль |
| `%s` | Вывод нуль терминированной строки по адресу в консоль |
| `%x` | Вывод 64х битного значения в hex представлении в консоль |

## Структура проекта
<pre style="background-color: #1e1e2e; color: #cdd6f4; padding: 16px; border-radius: 8px;">
<strong style="color: #89b4fa;">📦 ./</strong>
├── <strong style="color: #89b4fa;">📁 build/</strong>          # build дирректория
├── <strong style="color: #89b4fa;">🟧 Makefile</strong>
├── <strong style="color: #89b4fa;">📰 README.md</strong>
└── <strong style="color: #89b4fa;">📁 src/</strong>
    ├── <strong style="color: #89b4fa;">main.c</strong>          # Тесты
    └── <strong style="color: #89b4fa;">showme.s</strong>        # Исходный код showme()
</pre>

## Зависимости
Для успешной сборки потребуется:
- NASM
- Clang(рекомендуется) или любой другой C компилятор
- Make

## Сборка
|Команда|Описание|
|-------|--------|
|`make`|Сборка проекта|
|`make clean`|Очистка|