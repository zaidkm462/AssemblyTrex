# Assembly T-Rex

This project is an Assembly-language reconstruction of a game originally
created for a **Computer Graphics** course. The original version was written
in C# and rendered and animated the scene pixel by pixel using bitmap
graphics.

This version recreates the same idea in **x86 Assembly**. It was built with
**TASM 1.4** and runs inside the **DOSBox-X** DOS emulator. The game draws
directly to VGA Mode 13h video memory at `A000:0000`, using a 320 x 200
resolution with 256 colours.

## Video


https://github.com/user-attachments/assets/8bafa2f1-d00e-4ae6-bee0-83ab9ec80720



## Requirements

- [DOSBox-X](https://dosbox-x.com/) (or its
  [GitHub repository](https://github.com/joncampbell123/dosbox-x))
- A copy of this project
- TASM 1.4 and TLINK  
  `Tasm.exe` and `Tlink.exe` are included in this repository.

## How to Run

1. Download or clone this project.
2. Install and launch DOSBox-X.
3. Mount the project directory from inside DOSBox-X. Replace the path with
   the location where you downloaded the project:

   ```dos
   mount c C:\path\to\AssemblyTrex
   c:
   ```

4. Assemble, link, and run the game:

   ```dos
   tasm trex
   tlink trex
   trex
   ```

   The commands create `TREX.OBJ` and `TREX.EXE` before launching the game.

## Controls

- **Space**, **Enter**, or **Up Arrow**: jump
- **Space** or **Enter** after `GAME OVER`: restart
- **Esc**: exit

## Project Files

- `TREX.ASM` - Main Assembly source code
- `Tasm.exe` - TASM 1.4 assembler
- `Tlink.exe` - TASM linker
- `README.txt` - Original project notes

## Technical Notes

- The game uses VGA Mode 13h (`320 x 200`, `256` colours).
- Drawing is performed pixel by pixel through direct video-memory access.
- The background is white and the game artwork is black.
- The original C# version used a 25 ms Windows timer. This DOS version uses
  the BIOS timer tick to control the game loop.

Enjoy!
