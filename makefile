a.out: y.tab.cpp lex.yy.c
	g++ -O3 lex.yy.c y.tab.cpp
	@echo "Run the program as ./a.out < [input_file]"

y.tab.cpp: a.y
	yacc -d a.y -o y.tab.cpp

lex.yy.c: a.l y.tab.hpp
	lex a.l

clean:
	@rm -f lex.yy.c y.tab.hpp y.tab.cpp a.out summary.txt assembly.s
