beatnik.prg: main.asm helpers.asm poem.asm loop.asm dict.asm
	64tass -C -a -B -L beatnik.labels -i $< -o $@
	#pucrunch -ffast -x 2048 beatnik.tmp >beatnik.prg
