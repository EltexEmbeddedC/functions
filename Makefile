PROGRAM = password_checker
BINDIR = bin
SRCDIR = src

CC = gcc
CFLAGS = -fno-stack-protector -no-pie

SRCS = $(wildcard $(SRCDIR)/*.c)

OBJS = $(SRCS:$(SRCDIR)/%.c=$(SRCDIR)/%.o)

all: $(BINDIR)/$(PROGRAM)

$(BINDIR)/$(PROGRAM): $(OBJS)
	@mkdir -p $(BINDIR)
	$(CC) $(CFLAGS) -o $@ $^

$(SRCDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	rm -f $(SRCDIR)/*.o $(BINDIR)/$(PROGRAM)
