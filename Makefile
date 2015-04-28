mypc: y.tab.o lex.yy.o
	g++ -g -o mypc y.tab.o lex.yy.o -ll -ly Tree.cpp Scope.cpp Gencode.cpp
y.tab.o: y.tab.cpp
	g++ -g -c y.tab.cpp 2>&1 | grep -v Wwrite-strings
y.tab.cpp: pc.y
	yacc -dv pc.y -o y.tab.cpp
lex.yy.o: lex.yy.cpp
	gcc -g -c lex.yy.cpp 2>&1 | grep -v Wwrite-strings
lex.yy.cpp: pc.l
	flex -l -o lex.yy.cpp pc.l
clean:
	rm -f lex.yy.* y.tab.* *.o mypc y.output a.out a.s
