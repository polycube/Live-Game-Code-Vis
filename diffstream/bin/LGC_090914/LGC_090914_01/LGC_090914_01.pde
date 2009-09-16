background(0);
noStroke();

//no 4th arg means 100% opaque
fill(0,0,255);
rect(0,0,100,200);

//255 as 4th arg means 100% opaque
fill(255,0,0,255);
rect(0,0,200,40);

//191 means 75% opaque
fill(255,0,0,191);
rect(0,50,200,40);

//127 means 50% opacity
fill(255,0,0,127);
rect(0,100,200,40);

//63 means 25% opacity
fill(255,0,0,63);
rect(0,150,200,40);
