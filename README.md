# Wang Tile Set Creator

A simple Conversion Tool for the 4 Base Tiles of a Wang/DualMap TileSet according to the [Godot Template](https://user-images.githubusercontent.com/47016402/87044518-ee28fa80-c1f6-11ea-86f5-de53e86fcbb6.png) and the filler tiles.

<img width="720" alt="overview" src="https://github.com/user-attachments/assets/9b5577ef-547d-43e1-aa4a-3ffe3e6ae180">


The tool is written in Godot 4.3 and published under MIT License.

You simply import your tiles into the converter, it recreates the texture after every import, so you can check step by step if the result will be as expected. 
The tile and tile set gets calculated from the first imported tile, since they should always have the same size.

The area of your border tiles, wich should be filled with the overlay fill texture, should be white. 
Shadows outside of the fill area should be no problem, but within fill will propably not work.

`If the border itself isn't pixel perfect, the result can have some white areas. in this case, adjust the alpha tolerance factor. `

 
If your tile set has no underlay fill tile, ignore the underlay fill button and it will these areas will be transparent.



# Examples

*Step by Step Creation*

<img width="720" alt="example_1" src="https://github.com/user-attachments/assets/86900098-523d-4524-909b-e52889611e16">


*Result 1*

<img width="785" alt="example_2" src="https://github.com/user-attachments/assets/91f35829-afaf-4169-af39-d69ffc2b07f9">

*Result 2*

<img width="785" alt="example_3" src="https://github.com/user-attachments/assets/c12a77a0-ca73-4d97-aa53-ea99b9d29771">

*TileSet without underlay*

<img width="785" alt="example_4" src="https://github.com/user-attachments/assets/22f96d1d-8718-42fa-9540-7444f68a43b7">

*TileSet with outer shadow but non white border areas*

<img width="785" alt="grass_shadow" src="https://github.com/user-attachments/assets/98894422-89f6-4994-9f12-6e679136d6b5">
