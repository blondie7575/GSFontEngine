#
#  Makefile
#  GS Cats
#
#  Created by Quinn Dunki on 7/14/15.
#  One Girl, One Laptop Productions
#  http://www.blondihacks.com
#


CL65=cl65
CAD=./cadius
VOLNAME=GSAPP
IMG=DiskImageParts
EMU=/Applications/GSplus.app/Contents/MacOS/gsplus
ADDR=0800
EXEC=$(PGM)\#06$(ADDR)
FONTBANK=FONTBANK\#060000

PGM=fontdemo

all: clean diskimage fonts $(PGM) emulate

emulate:
	# Leading hypen needed because GSPlus maddeningly returns code 1 (error) always and for no reason
	-/Applications/GSplus.app/Contents/MacOS/gsplus
	
diskimage:
	$(CAD) CREATEVOLUME $(PGM).2mg $(VOLNAME) 800KB
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(IMG)/BITSY.BOOT/BITSY.BOOT#FF2000
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(IMG)/QUIT.SYSTEM/QUIT.SYSTEM#FF2000
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(IMG)/PRODOS/PRODOS#FF0000
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(IMG)/BASIC.SYSTEM/BASIC.SYSTEM#FF2000
		
$(PGM):
	@PATH=$(PATH):/usr/local/bin; $(CL65) -t apple2enh --cpu 65816 --start-addr 0800 -l$(PGM).lst $(PGM).s -o $(EXEC)
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(EXEC)
	$(CAD) ADDFILE $(PGM).2mg /$(VOLNAME) $(FONTBANK)

	rm -f $(EXEC)
	rm -f $(FONTBANK)
	rm -f $(PGM).o

fonts:
	rm -rf $(FONTBANK)
	./CompileFont.py 8 8 32 14 "font8" "Font8x8.gif" > font8x8.s
	./CompileFont.py 16 16 32 14 "font16" "Font16x16.gif" > font16x16.s
	@PATH=$(PATH):/usr/local/bin; $(CL65) -t apple2enh -C linkerConfig --cpu 65816 --start-addr 0000 -lfonts.lst fontEngine.s -o $(FONTBANK)
	rm -f fontEngine.o

clean:
	rm -f $(PGM)
	rm -f $(PGM).o
	rm -f $(PGM).2mg

