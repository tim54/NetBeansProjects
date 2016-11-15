IDIR =../include
CC=gcc
CXX=g++

CFLAGS=-I$(IDIR) -std=c++11

ODIR=obj
LDIR =../lib

LIBS=-lm

_DEPS = Date.h string_sprintf.h
DEPS = $(patsubst %,$(IDIR)/%,$(_DEPS))

_OBJ = usefultest.o Date.o
OBJ = $(patsubst %,$(ODIR)/%,$(_OBJ))

$(ODIR)/%.o: %.c $(DEPS)
	@mkdir -p $(@D)
	$(CC) -c -o $@ $< $(CFLAGS)

$(ODIR)/%.o: %.cpp $(DEPS)
	@mkdir -p $(@D)
	$(CXX) -c -o $@ $< $(CFLAGS)

usefultest: $(OBJ)
	$(CXX) -o $@ $^ $(CFLAGS) $(LIBS)

.PHONY: clean

clean:
	rm -f $(ODIR)/*.o *~ core $(INCDIR)/*~
