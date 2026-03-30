#include <stdio.h>

extern void showme (const char*, ...);

int main ()
{
    showme ("%%c\n");

    showme ("%c\n", 'A'); 
    printf ("%c\n", 'A'); 
    showme ("%c%c%c\n", '1', '2', '3'); 
    printf ("%c%c%c\n", '1', '2', '3');

    printf ("\n");

    printf ("%%d\n");

    showme ("%d\n", 123); 
    printf ("%d\n", 123); 
    showme ("%d\n", -456); 
    printf ("%d\n", -456); 
    showme ("%d %d %d\n", 0, 100, -100);
    printf ("%d %d %d\n", 0, 100, -100); 

    printf ("\n");

    printf ("%%s\n");

    showme ("%s", "Hell\n"); 
    printf ("%s", "Hell\n"); 
    showme ("%s %s", "foo", "bar\n"); 
    printf ("%s %s", "foo", "bar\n"); 

    printf ("\n");

    printf("%%x\n");

    showme ("%x\n", 0xdeadbeef);
    printf ("%x\n", 0xdeadbeef);

    printf ("\n");

    printf ("%%b\n");

    showme ("%b\n", 10); 
    printf ("1010\n"); 
    showme ("%b %b\n", 0, 1); 
    printf ("0 1\n"); 

    printf ("\n%%f\n");
    showme ("%f %f %f %f %f %f %f %f %f %f %f\n", -3.75, 25.43, 234.234, 2032.234, 4534.23, 949.34, 349.43, 324.245, 3745.34, 98234.1298, 0.);
    printf ("%f %f %f %f %f %f %f %f %f %f %f\n", -3.75, 25.43, 234.234, 2032.234, 4534.23, 949.34, 349.43, 324.245, 3745.34, 98234.1298, 0.);

    printf("\n");

    showme ("%d %s  %x %d%%%b%c\n", -1, "love", 3802, 100, 31, 33);
    printf ("%d %s  %x %d%%%b%c\n", -1, "love", 3802, 100, 31, 33);

    showme ("ggs\n");

    return 0;
}