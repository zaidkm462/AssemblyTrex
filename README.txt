T-REX - TASM 1.4 / DOSBox-X
============================

Files:
  TREX.ASM   Main Assembly source
  BUILD.BAT  Build script for TASM 1.4 + TLINK

The source uses VGA Mode 13h (320x200, 256 colors) and direct video memory
at A000:0000. The original T-Rex/tree vertical drawing dimensions are kept;
only the horizontal starting gap is compressed to fit 320 pixels.

Controls:
  SPACE or ENTER = jump
  SPACE/ENTER after GAME OVER = restart
  ESC = exit

Default TASM path in BUILD.BAT:
  C:\TASM\BIN\TASM.EXE
  C:\TASM\BIN\TLINK.EXE

If your TASM is elsewhere, edit the TASM variable in BUILD.BAT.

DOSBox-X example:
  mount c C:\your\folder\TREX_TASM14
  c:
  build
  trex.com

Note: The original C# game uses a Windows timer of 25 ms. This DOS version
uses the BIOS timer tick for a stable simple DOS implementation. The drawing
itself is VGA Mode 13h, not a DOS graphics library.
