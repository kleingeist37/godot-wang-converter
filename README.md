# Wang Tile Set Creator

A simple Conversion Tool for the 4 Base Tiles of a Wang/DualMap TileSet and the filler tiles.

<img width="721" alt="overview" src="https://github.com/user-attachments/assets/165b5135-3d5f-4ca3-893d-65ce1b3f581b">


The tool is written in Godot 4.3 and published under MIT License.

You simply import your tiles into the converter, it recreates the texture after every import, so you can check step by step if the result will be as expected. 
The tile and tile set gets calculated from the first imported tile, since they should always have the same size.

The area of your border tiles, wich should be filled with the overlay fill texture, should be white. 
Shadows outside of the fill area should be no problem, but within fill will propably not work.

`If the border itself isn't pixel perfect, the result can have some white areas. in this case, adjust the alpha tolerance factor. `

 
If your tile set has no underlay fill tile, ignore the underlay fill button and it will these areas will be transparent.



Here are some example:

*Step by Step Creation*

<img width="721" alt="example_1" src="https://github.com/user-attachments/assets/c977653e-fdcd-49a5-8a84-ccea8eca9298">

*Result 1*

<img width="721" alt="example_2" src="https://github.com/user-attachments/assets/a1356a58-e116-45a9-861b-87aa2f89f044">

*Result 2*

<img width="721" alt="example_3" src="https://github.com/user-attachments/assets/b1485924-7fe8-4459-9453-1d647d111155">

*TileSet without underlay*

<img width="721" alt="example_4" src="https://github.com/user-attachments/assets/af6cb2fa-dffa-4ed4-b8cd-80344da9dea2">

*TileSet with outer shadow*

<img width="721" alt="grass_shadow" src="https://github.com/user-attachments/assets/8ece160f-0237-4c53-948e-b6ed1e986bcc">
