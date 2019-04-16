The purpose of the GitHub repository is to showcase my course project for CSC258H1 Course (https://fas.calendar.utoronto.ca/course/csc258h1). All source files for my project are included in the repository.

# Before you start
Please make sure you have:
- Intel® Quartus® Prime Software (https://www.intel.ca/content/www/ca/en/software/programmable/quartus-prime/download.html) _AND_ 
- DoC-SE1 Board, which can be purchased at https://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=836.

The Intel® Quartus® Prime Software can be downloaded at http://fpgasoftware.intel.com/18.1/?edition=lite. Apple users do need to install a Windows or Ubuntu virtual machine before working with Intel® Quartus® Prime Software. 

# Run the project:
Please follow the following steps for downloading the compiled project to the board:
- Connect your DoC-SE1 board to your machine and open Quartus®.
- Click Tools -> Programmer. A window will pop-out.
- Click Hardware Setup. You should see the connected board in the window popped out.
- Double Click the DE1-SoC board, and press "OK".
- Delete everything in the file list.
- Press "Auto Detect", then select "5CSEMA" before pressing "OK".
- Double Click the "5CSEMA5" device, and import the output file from the output folder.
- Press "Start" to download the compiled code to the board.

It is now time to play with the game:
- KEY[3:0] controls the direction in which the snake moves: KEY[3] for up, KEY[2] for down, KEY[1] for left and KEY[0] for right. 
- SW[0] is the reset switch for the game. It should be placed at the "off" position when downloading the compiled project to the board.
- The game has obstacle and tunnel features -- the snake may travel through the tunnel (enter through one end and exit through the other), and the game will terminate if the snake hits the obstacle.

# Important: 
Files repository were sent to the Department of Computer Science at the University of Toronto at the course coordinator's request, and has been included in the department's database for academic offense detections. The source code in this repository is not intended to be reused for academic purposes.
