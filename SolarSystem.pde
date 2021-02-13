PVector sun;

ArrayList<Planet> planets;

final float FAC_GRAV = 100000;
final float FAC_NEWP = 0.1;

final float SUN_RADIUS = 64;

float newPlanetRadius;
color newPlanetColour;

float barPos;

float wd3;
float colSegWidth;
float wd3csw;

//Settings -->
int trailLength = 100;
boolean trailTracking = true;
boolean trailHQ = true;
boolean simRunning = true;
boolean showHeadingLine = false;
boolean showVelocity = false;
boolean showColourBar = true;

float mouseSize = 32;
PVector[] mouse = {new PVector(0, 0), new PVector(0, 1), new PVector(0.225, 0.839711), new PVector(0.5, 0.866025)};

void settings() {
  fullScreen(P2D); //P2D is needed for the trails
  PJOGL.setIcon("icon.png");
}

void setup() {
  colorMode(HSB);
  noCursor();
  wd3 = width/3;
  colSegWidth = wd3/128;
  wd3csw = wd3 + colSegWidth;

  sun = new PVector(width/2, height/2);
  planets = new ArrayList<Planet>();
  float barHeight = 12;
  barPos = height - barHeight;

  newPlanetRadius = 16;
  newPlanetColour = color(random(255), 255, 255);

  for (PVector p : mouse)
    p.mult(mouseSize).add(new PVector(1, 3));
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
    if (mouseButton == LEFT) {
      //Relative End Coordinates -->
      nPvx = nPx - mouseX;
      nPvy = nPy - mouseY;
      //Add Planet -->
      if (dist(nPx, nPy, sun.x, sun.y) > SUN_RADIUS) { //Not in sun
        planets.add(new Planet(nPx, nPy, nPvx, nPvy, newPlanetRadius, newPlanetColour));
      }

      if (!simRunning) {
        showHeadingLine = true; //Spawned a new planet while paused makes heading lines show
      }
    }
  }
}

void draw() {
  background(0, 0, 10);

  //Planets -->
  for (int i = planets.size() - 1; i >= 0; i--) {
    Planet p = planets.get(i);
    if (!mousePressed && simRunning) {
      if (dist(p.pos, sun) < p.radius + SUN_RADIUS)
        planets.remove(i);

      p.applyForce(attract(p));
      p.update();
    }
    p.render();
  }

  //Sun -->
  noStroke();
  fill(32, 255, 255);
  circle(sun.x, sun.y, SUN_RADIUS *2);

  //Mouse Actions -->
  if (mousePressed) {
    if (nPy < barPos) {
      stroke(255);
      strokeWeight(3);
      noFill();
      if (mouseButton == LEFT && dist(nPx, nPy, sun.x, sun.y) > SUN_RADIUS) { //Catapult Graphic
        circle(nPx, nPy, newPlanetRadius *2);
        strokeCap(ROUND);
        line(nPx, nPy, nPx + FAC_NEWP*(nPx - mouseX), nPy + FAC_NEWP*(nPy - mouseY));
      } else if (mouseButton == RIGHT) { //Size Graphic
        newPlanetRadius = constrain(dist(nPx, nPy, mouseX, mouseY), 8, SUN_RADIUS*2/3);
        circle(nPx, nPy, newPlanetRadius *2);
      }
    } else if (nPy > barPos && mouseX < wd3csw && showColourBar) {
      //Colour Picker
      newPlanetColour = color(map(mouseX, 0, wd3csw, 0, 255), 255, 255);
      stroke(128);
      strokeWeight(10);
      fill(newPlanetColour);
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

  //Custom Cursor -->
  pushMatrix();
  translate(mouseX, mouseY);
  noFill();
  stroke(255, 128);
  strokeWeight(3);
  beginShape();
  for (PVector p : mouse)
    vertex(p.x, p.y);
  endShape(CLOSE);
  stroke(255, 200);
  strokeWeight(1);
  beginShape();
  for (PVector p : mouse)
    vertex(p.x, p.y);
  endShape(CLOSE);
  popMatrix();
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
      trailTracking = !trailTracking;
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
      trailHQ = !trailHQ;
      break;
    case 'x': //remove a hovered over planet
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(mouseX, mouseY, p.pos.x, p.pos.y) < p.radius) {
          planets.remove(i);
        }
      }
      break;
    case 'z': //remove offscreen planets
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (!p.onScreen) {
          planets.remove(i);
        }
      }
      break;
    case 's':
      break;
    }
  }
}

float dist(PVector v1, PVector v2) {
  return dist(v1.x, v1.y, v2.x, v2.y);
}
