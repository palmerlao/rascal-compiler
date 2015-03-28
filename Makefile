mypc: y.tab.o lex.yy.o
	g++ -g -o mypc y.tab.o lex.yy.o -ll -ly
y.tab.o: y.tab.cpp
	g++ -g -c y.tab.cpp
y.tab.cpp: pc.y
	yacc -dv pc.y -o y.tab.cpp
lex.yy.o: lex.yy.c
	gcc -g -c lex.yy.c
lex.yy.c: pc.l
	lex -l pc.l
clean:
	rm -f lex.yy.* y.tab.* *.o mypc y.output
