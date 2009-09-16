size(200,200);
background(255);
noStroke();

//reddish brown parts
fill(100,50,0); 
triangle(10,2,12,12,8,30);  //ear 1
triangle(30,0,40,20,25,25);  //ear 2
ellipseMode(CORNERS);  
ellipse(45,15,0,75);    //head
quad(45,20,35,50,60,100,80,80);  //neck
ellipse(75,75,175,150);  //body
rect(70,130,15,70);   // leg 1
rect(90,130,15,70);  //leg 2
rect(120,130,15,70);  //leg 3
rect(140,130,15,70);  //leg 4

//black-brown parts
fill(50,50,0);
rect(20,20,10,15);  //forelock
quad(45,20,35,25,70,75,80,80); //mane
quad(170,100,165,110,170,170,200,150);  //tail
ellipse(20,40,25,45);  //eye

//text
println("Neeeeeeeeeeeeiiiiigggghhhhh");

