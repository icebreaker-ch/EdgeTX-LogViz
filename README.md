# LogViz
A tool to visualize log entries, recorded by the SD Logging special function
on an [EdgeTX](https://github.com/EdgeTX/edgetx) B&W or color radio.

The tool was originally inspired by the  [LogViewerBW tool](https://github.com/nikbg3/EdgeTXLogViewerBW) by Nikolay Kolev but I wanted
to improve the user interface and simplify operation.

The script has been tested on the following radios:
- Radiomaster Zorro
- Horus X12S
- Horus X10S
- Taranis X7 ACCESS
- Taranis X9D+ 2019

**Author:** Roland Schäuble (icebreaker)

## Features and Operation
The start screen allows selection of Model, Logfile and Log-Entry (Field) to be visualized.
Navigation/Selection with the Rotary Wheel and ```Enter```.
Press ```Enter``` on ```View Log``` to display the selected entry. Only one entry can be selected/displayed at a time (memory limitations)

The cursor on the Log View screen can be moved (slowly) by turning the Rotary wheel or
(faster) by Stick #1 (Aileron).

When moving the cursor, the time stamp of the cursor position is displayed as a tooltip for 1 second.

To view the time stamp of the current cursor position, press ```Enter```

## Screenshots
### Radiomaster Zorro
![screenshot_zorro_25-06-15_08-48-46](https://github.com/user-attachments/assets/36151dc7-2829-4060-95dd-5586a79cb925)
![screenshot_zorro_25-06-15_08-48-35](https://github.com/user-attachments/assets/a964c060-7366-4ada-968e-780b93bf1401)
![screenshot_zorro_25-06-15_13-04-28](https://github.com/user-attachments/assets/6ff96b18-a23d-4822-abf1-8a6ae3aeb365)

### Taranis X9D
![screenshot_x9d+2019_25-06-15_08-27-02](https://github.com/user-attachments/assets/6b85400b-0fb4-4a66-907f-553811f06e46)
![screenshot_x9d+2019_25-06-15_08-28-14](https://github.com/user-attachments/assets/7ed2db23-bc2c-4d1c-9e8e-ded841525bdb)

### Horus X12S
![screenshot_x12s_25-06-15_08-22-59](https://github.com/user-attachments/assets/22a89620-1a8d-4489-9a33-0b33b0172143)
![screenshot_x12s_25-06-15_08-23-47](https://github.com/user-attachments/assets/29d73ab6-9096-4729-b385-004caf8585be)


## Installation
Copy the file ```LogViz.lua``` and the folder ```LogViz``` to the ```/SCRIPTS/TOOLS``` folder on the SD card.

## Known problems
Due to memory limitations (especially on B&W Radios), it is possible, to run out of memory
when reading large Logfiles. However, Logfiles of 800k have been tested without problems.
