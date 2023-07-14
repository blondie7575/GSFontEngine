# GSFontEngine

### Introduction
While working on a game for my Apple IIgs, I found myself in need of a flexible text rendering engine that could handle cool Amiga-scene-style fonts, and was reasonably performant. After writing it, I realized it's pretty modular, easy to factor out, and might be of use to others. So here it is! In a pinch, you could use this as a sprite renderer also!

### Theory of Operation
In a nutshell, this is a font compiler. It takes a GIF image of all the glyphs in your font, arranged in a grid. There is a Python script which parses that image, finds all the glyphs, and generates 65186 assembly code to render each glyph on the Apple IIgs as quickly as possible. Because the Apple IIgs is a strange beast, this is easier said than done! Finally, there is a little bit of wrapper code for drawing strings using that generated code anywhere you like.

Included in this repository is a little demo program that shows how to use it, and also demonstrates how you can set up a Makefile to generate your fonts at runtime, then have them loaded as a code bank from the floppy directly into IIgs RAM. In this example, the font bank (FONTBANK on the disk image) is compiled with ca65, then at runtime is loaded into RAM bank 5. The main entry point is at $0000, so drawing a string on screen is as simple as `jsl $050000`


### IIgs Graphics Crash Course
The IIgs has an achilles heel, which is that all writes to the Super High-Res graphics page are done at 1MHz instead of full system speed. This is a terrible thing, related to backward compatibility. However, the IIgs has some insane tricks up its sleeve to minimize this pain. The system allows shadowing memory banks, such that writes can be done to multiple banks simultaneously. Furthermore, you can relocate the stack anywhere in bank 0 or 1. Combining these tricks means if we locate the stack in the same place in bank 1 where the SHR page would be in its own bank, we can then use stack operations to *push* pixels on to the screen. Stack operations are really fast, so while it's still 1Mhz, we're saving a lot of clock cycles. With register pushes, we can achieve less than one clock cycle per pixel. Much much faster than basic copying bytes around with `lda` and `sta` would be.

The final touch is that the GS has a huge amount of RAM relative to its screen resolution, and relative to other 16-bit machines. That means we can use large amounts of space for things like compiling sprites and fonts. This demo, for example, has two fonts in it, and the total compiled code size to render all those characters is nearly 32k. That would be unthinkable on most 16-bit machines, but on the GS it's hardly a drop in the giant bucket of RAM we have.

### The Compiler
The font compiler is written in python and generates human-readable ca65 source code. You can then include this source directly in your project, or more likely you'll want to set up your makefile to build this code as a separate object file loaded at runtime. The included demo shows this approach.

I won't claim the generated code is as fast as it can possibly be. I'm sure there are optimizations that could be made. However it's easy to follow and pretty close to the speed limits, I'd say. Where possible, four-pixel pushes are done with `pea`. Around the edges of characters, where detail is needed, the bytes are combined with the background using `and` and `or` operations. These are done using stack relative addressing with `lda` and `sta`. Stack-relative addressing is a secret super-power of the 65816 that is really useful in sprite compilers. The operations over a couple of rows are arranged and optimized to combine stack pointer moves and keep within range of stack-relative addressing.

The ideas in this compiler borrow quite a bit from [Mr. Sprite](http://www.brutaldeluxe.fr/products/crossdevtools/mrsprite/index.html), and I'm of course endebted to the amazing work Brutal Deluxe has done there.

Note that the font compiler requires Python 3, and the `Pillow` and `numpy` modules (both installable with `pip`)

### Using the Font Engine
The font compiler will generate a couple of enormous source files, each with an entry point to render each character in your font. You specify the ASCII code of the first glyph (starting with ! or space is typical) and a prefix (to separate multiple fonts from each other). Inside the font engine, you'll find a jump table which you can edit to include all your fonts. You can have as many fonts active at once as you want, RAM permitting. When rendering a string, you provide a Pascal string pointer, the font index, and a VRAM position to render at. Like most GS things, VRAM position is a 16-bit index into VRAM. You could write a wrapper to calculate the VRAM index from screen position, but that would be a lot of math that is better done at build time.

**Important!** Since this is stack-based rendering, the VRAM position is the *lower right* corner of your string, and rendering actually takes place upwards and backwards in your string. 

### Future Work
I'm sure there are ways to make the compiled code faster. If you're writing scene demos, maybe it wouldn't be fast enough as is (but it should be close). If you're writing a game, it's probably already faster than you need because games rarely need text drawing to be blazing fast.

It would not be difficult to extend this to be a general purpose sprite compiler. That's already what it is, it's just assuming all sprites are in a single sheet and are the same size. For many games, that's already enough sprite compiler for you.

Currently it requires a chroma key colour, which does cost you one colour in your font sheets. You can still use that missing colour in other graphics in your game, it just can't be used at sprite-compile time.

Currently fonts are only monospaced. It would be really cool to add proportional support, and it wouldn't be super difficult. The added complexity is unlikely to be needed for most use cases though, so I didn't do it in this first version.
