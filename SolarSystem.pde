PVector sun;

ArrayList<Planet> planets;

final float FAC_GRAV = 100000;
final float FAC_NEWP = 0.1;

final float DIAM_SUN = 128;
final float DIAM_PLA = 32;
final float DIAM_NPL = 64;

float barPos;
color pCol;

float wd3;
float colSegWidth;
float wd3csw;

//Settings -->
boolean simRunning = true;
boolean trackTrail = true;
boolean showHeadingLine = false;
boolean showVelocity = false;
boolean showColourBar = true;
boolean trackHQ = true;

void setup() {
  fullScreen();
  colorMode(HSB);
  wd3 = width/3;
  colSegWidth = wd3/128;
  wd3csw = wd3 + colSegWidth;

  sun = new PVector(width/2, height/2);
  planets = new ArrayList<Planet>();
  float barHeight = 12;
  barPos = height - barHeight;
  pCol = color(random(255), 255, 255);
}

float nPx, nPy;
float nPvx, nPvy;
void mousePressed() {
  //Start Coordinates -->
  nPx = mouseX;
  nPy = mouseY;
}

void mouseReleased() {
  if (nPy < barPos) {
    //End Coordinates -->
    nPvx = nPx - mouseX;
    nPvy = nPy - mouseY;

    //Add Planet -->
    if (dist(nPx, nPy, sun.x, sun.y) > DIAM_SUN/2) { //Not in sun
      planets.add(new Planet(nPx, nPy, nPvx, nPvy, pCol));
    }

    if (!simRunning) {
      showHeadingLine = true;
    }
  }
}

void draw() {
  background(0, 0, 10);

  //Planets -->
  for (int i = planets.size() - 1; i >= 0; i--) {
    Planet p = planets.get(i);
    if (!mousePressed && simRunning) {
      if (dist(p.pos, sun) < DIAM_SUN/2)
        planets.remove(i);

      p.applyForce(attract(p));
      p.update();
    }
    p.render();
  }

  //Sun -->
  noStroke();
  fill(32, 255, 255);
  circle(sun.x, sun.y, DIAM_SUN);

  //Mouse Actions -->
  if (mousePressed) {
    if (nPy < barPos) {
      //Catapult Graphic -->
      stroke(255);
      strokeWeight(4);
      strokeCap(ROUND);
      noFill();
      circle(nPx, nPy, DIAM_NPL);
      line(nPx, nPy, nPx + FAC_NEWP*(nPx - mouseX), nPy + FAC_NEWP*(nPy - mouseY));
    } else if (nPy > barPos && mouseX < wd3csw && showColourBar) {
      //Colour Picker
      pCol = color(map(mouseX, 0, wd3csw, 0, 255), 255, 255);
      stroke(128);
      strokeWeight(10);
      fill(pCol);
      rect(mouseX, barPos - 32, width/10, -width/10, 20);
    }
  }

  //Colour Picker Render -->
  if (showColourBar) {
    strokeWeight(colSegWidth);
    strokeCap(SQUARE);
    for (float i = 0; i < wd3+1; i+=colSegWidth) {
      stroke(map(i, 0, wd3, 0, 255), 255, 255, 200);
      line(i + colSegWidth/2, barPos, i + colSegWidth/2, height);
    }
  }
}

PVector attract(Planet p) {
  PVector f = PVector.sub(sun, p.pos);
  float d = f.mag();
  f.normalize();
  float s = FAC_GRAV / (d*d);
  f.mult(s);
  return f;
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    }
  } else {
    switch(key) {
    case ' ':
      simRunning = !simRunning;
      break;
    case 't':
      trackTrail = !trackTrail;
      break;
    case 'h':
      showHeadingLine = !showHeadingLine;
      break;
    case 'v':
      showVelocity = !showVelocity;
      break;
    case 'c':
      showColourBar = !showColourBar;
      break;
    case 'q':
      trackHQ = !trackHQ;
      break;
    }
  }
}

float dist(PVector v1, PVector v2) {
  return dist(v1.x, v1.y, v2.x, v2.y);
}
