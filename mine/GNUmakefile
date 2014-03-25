# Languages supported by Exuberant Ctags
ECTAGS_LANGS = Make,C,C++,Pascal,Sh,Ada,D,Lisp
TAGS_FILES = *

all: tags
tags: GNUmakefile $(TAGS_FILES)
	@ctags --sort=yes --links=no --excmd=number --languages=$(ECTAGS_LANGS) --extra=+f --file-scope=yes --fields=afikmsSt --totals=yes $(TAGS_FILES)
clean:
	$(RM) tags TAGS
