size(200,200);
noFill();


stroke(200,30,20);
//angMode(RADIANS);
arc(50, 55, 80, 50, PI/3, PI);

float rad = TWO_PI;
float deg = degrees(rad);
println(rad + " radians is " + deg + " degrees");
smooth();
strokeWeight(1);   // Default
line(20, 20, 80, 20);
strokeWeight(4);   // Thicker
line(20, 40, 80, 40);
strokeWeight(10);  // Beastly
line(20, 70, 80, 70);
