CC = gcc
CFLAGS = -Wall

PROG = main<+CURSOR+>

SRCS = main.c
LIBS =

$(PROG): $(SRCS) $(LIBS)
	$(CC) $(CFLAGS) -o $(PROG) $<

clean:
	rm -rf *.o $(PROG)
