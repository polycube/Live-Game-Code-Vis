size(200,200);
noFill();
smooth();
strokeWeight(6);   // Thicker
stroke(200,30,20);
//angMode(RADIANS);
arc(150, 155, 80, 50, PI/3, PI);

float rad = TWO_PI;
float deg = degrees(rad);
println(rad + " radians is " + deg + " degrees");
smooth();
strokeWeight(1);   // Default
line(20, 80, 80, 20);
strokeWeight(1.5);   // Thicker
line(20, 100, 80, 40);
strokeWeight(2);  // Beastly
line(20, 120, 80, 70);
