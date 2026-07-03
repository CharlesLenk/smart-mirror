# Smart Mirror PI Case

`screen case.scad` contains case for mounting a Raspberry PI with official 7" display inside of a smart mirror. The PI
cover clips in place and can be easily removed for maintenance.

`cable clip.scad` and `spacer.scad` are optional mounting hardware.

# Project Setup for Local Editing

Everything below this point is only relevant if you want to download this project and make edits.

## Cloning this Repository

This project uses a submodule for common SCAD code. If the submodule is not initialized, the `openscad-utilities` directory will be empty, and the project won't render.

To get the submodule code when cloning, add the `--recurse-submodules` option to the clone command. For example:
> `git clone [Project URL] --recurse-submodules`

If you've already cloned the project, run this command in the project root to pull down the submodule:
> `git submodule update --init`

## Exporting Model Files

There are two options for exporting the models:

1. Manually through the [OpenSCAD](https://openscad.org/) UI.
2. Through the provided export script.

As of 2024, the OpenSCAD development preview uses a new rendering engine called Manifold. Using the development preview with Manifold will render the models many times faster, regardless of how you export this project.

### 1. Exporting Manually

The `export map.scad` file contains an `if/else` condition where the call to generate each part can be seen. You can either write OpenSCAD code using these calls to build up a print plate, or the part "name" can be manually edited to select each part, which can then be rendered and exported through the OpenSCAD UI like any other project.

### 2. Exporting using the Script

The export script, `export.py`, depends on the [SCAD Export](https://github.com/CharlesLenk/scad_export) library. To use this script follow the instructions in the SCAD Export documentation.
