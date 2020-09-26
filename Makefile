a.out: y.tab.c lex.yy.c
	gcc -O3 lex.yy.c y.tab.c
	@echo "Run the program as ./a.out [input_file]"

y.tab.c: yacc.y 
	yacc -d yacc.y

lex.yy.c: lex.l y.tab.h
	lex lex.l

clean:
	@rm -f lex.yy.c y.tab.h y.tab.c a.out

