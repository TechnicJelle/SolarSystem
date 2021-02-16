PVector sun;

ArrayList<Planet> planets;

final float FAC_GRAV = 100;
final float FAC_NEWP = 0.1;

final float SUN_RADIUS = 64;
final float SUN_MASS = 500;

final float MIN_PLANET_RADIUS = 8;
final float MAX_PLANET_RADIUS = SUN_RADIUS * 2/3;

final float MIN_PLANET_MASS = 10;
final float MAX_PLANET_MASS = SUN_MASS * 2/3;

final float TEXT_SIZE = 20;

final int timeStepsPerFrame = 10;

float newPlanetMass;
float newPlanetRadius;
float newPlanetHue;
color newPlanetColour;
PVector newPlanetPos;
PVector newPlanetVel;

PGraphics system;
PGraphics gizmos;

float barPos;

float wd3;
float colSegWidth;
float wd3csw;

boolean simHalted = false;

final int alternateButton = SHIFT; //ALT, because alternate
boolean alternateAction = false;

//Settings -->
int trailLength = 100;
boolean trailTracking = true;
boolean trailHQ = true;
boolean simRunning = true;
boolean showHeadingLine = false;
boolean showProperties = false;
boolean showColourBar = true;

float mouseSize = 32;
PVector[] mouse = {new PVector(0, 0), new PVector(0, 1), new PVector(0.225, 0.839711), new PVector(0.5, 0.866025)};

void settings() {
  fullScreen(P2D); //P2D is needed for the trails
  smooth(2);
  PJOGL.setIcon("icon.png");
}

void setup() {
  colorMode(HSB);
  hint(ENABLE_ASYNC_SAVEFRAME);
  noCursor();

  system = createGraphics(width, height, P2D); //P2D is needed for the trails
  gizmos = createGraphics(width, height);

  wd3 = width/3;
  colSegWidth = wd3/128;
  wd3csw = wd3 + colSegWidth;

  sun = new PVector(width/2, height/2);
  planets = new ArrayList<Planet>();
  float barHeight = 12;
  barPos = height - barHeight;

  newPlanetMass = round(MAX_PLANET_MASS/2);
  newPlanetRadius = 16;
  newPlanetHue = random(255);
  updateNewPlanetColour();

  for (PVector p : mouse)
    p.mult(mouseSize).add(new PVector(1, 3));
}

void mousePressed() {
  //Start Coordinates -->
  newPlanetPos = new PVector(mouseX, mouseY);
  simHalted = true;
}

void mouseReleased() {
  simHalted = false;
  if (newPlanetPos.y < barPos) {
    if (mouseButton == LEFT) {
      //Add Planet -->
      if (dist(newPlanetPos, sun) > SUN_RADIUS) { //Not in sun
        planets.add(new Planet(newPlanetPos, newPlanetVel, newPlanetMass, newPlanetRadius, newPlanetColour));
      }

      if (!simRunning) {
        showHeadingLine = true; //Spawned a new planet while paused makes heading lines show
      }
    }
  }
}

int startMassChangeTime;
boolean showingNewMass = false;
void mouseWheel(MouseEvent event) {
  startMassChangeTime = millis();
  showingNewMass = true;
  float e = event.getCount() * (alternateAction ? 4 : 1);
  newPlanetMass = constrain(newPlanetMass - e, MIN_PLANET_MASS, MAX_PLANET_MASS);
  updateNewPlanetColour();
}

void draw() {
  system.beginDraw();
  system.colorMode(HSB);
  system.background(170, 100, 5);

  //Planets -->
  if (!mousePressed && simRunning && !simHalted) {
    for (int t = 0; t < timeStepsPerFrame; t++) {
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(p.pos, sun) < p.radius + SUN_RADIUS)
          planets.remove(i);

        p.applyForce(attractMass(p));
        p.update(1/float(timeStepsPerFrame));
      }
    }
  }

  //Sun -->
  system.noStroke();
  system.fill(32, 255, 255);
  system.circle(sun.x, sun.y, SUN_RADIUS *2);


  if (frameCount > 1)
    gizmos.clear();
  gizmos.beginDraw();
  gizmos.colorMode(HSB);

  for (Planet p : planets) //Planets contain both system and gizmos graphics
    p.render();
  system.endDraw();

  //Mass Changer Gizmo Pop-Up -->
  if (millis() - startMassChangeTime > 1000) //Hide again after a second
    showingNewMass = false;
  if (showingNewMass) {
    gizmos.noStroke();
    gizmos.fill(255);
    gizmos.textSize(TEXT_SIZE);
    gizmos.textAlign(LEFT, BOTTOM);
    gizmos.text("m:" + round(newPlanetMass), mouseX, mouseY);
  }

  //Mouse Actions -->
  if (mousePressed) {
    if (newPlanetPos.y < barPos) {
      gizmos.stroke(255);
      gizmos.strokeWeight(3);
      gizmos.noFill();
      switch(mouseButton) {
      case RIGHT: //Size Graphic
        newPlanetRadius = constrain(dist(newPlanetPos.x, newPlanetPos.y, mouseX, mouseY) / (alternateAction ? 8 : 1), MIN_PLANET_RADIUS, MAX_PLANET_RADIUS);
        gizmos.circle(newPlanetPos.x, newPlanetPos.y, newPlanetRadius *2);
        break;
      case LEFT: //Catapult Graphic
        if (dist(newPlanetPos, sun) > SUN_RADIUS) {
          //Relative End Coordinates -->
          newPlanetVel = PVector.sub(newPlanetPos, new PVector(mouseX, mouseY));
          gizmos.circle(newPlanetPos.x, newPlanetPos.y, newPlanetRadius *2);
          gizmos.strokeCap(ROUND);
          gizmos.line(newPlanetPos.x, newPlanetPos.y, newPlanetPos.x + FAC_NEWP*(newPlanetPos.x - mouseX), newPlanetPos.y + FAC_NEWP*(newPlanetPos.y - mouseY));
        }
        break;
      }
    } else if (newPlanetPos.y > barPos && mouseX < wd3csw && showColourBar) {
      //Colour Picker Pop-Up
      newPlanetHue = map(mouseX, 0, wd3csw, 0, 255);
      updateNewPlanetColour();
      gizmos.stroke(newPlanetColour);
      gizmos.strokeWeight(10);
      gizmos.fill(color(newPlanetHue, 255, 255));
      gizmos.rect(mouseX, barPos - 32, width/10, -width/10, 20);
    }
  }

  //Colour Picker Bar -->
  if (showColourBar) {
    gizmos.strokeWeight(colSegWidth);
    gizmos.strokeCap(SQUARE);
    for (float i = 0; i < wd3+1; i+=colSegWidth) {
      gizmos.stroke(map(i, 0, wd3, 0, 255), 255, 255, 200);
      gizmos.line(i + colSegWidth/2, barPos, i + colSegWidth/2, height);
    }
  }

  //Custom Cursor -->
  gizmos.pushMatrix();
  gizmos.translate(mouseX, mouseY);
  gizmos.fill(newPlanetColour, 128);
  gizmos.stroke(255, 128);
  gizmos.strokeWeight(3);
  gizmos.beginShape();
  for (PVector p : mouse)
    gizmos.vertex(p.x, p.y);
  gizmos.endShape(CLOSE);
  gizmos.stroke(255, 200);
  gizmos.strokeWeight(1);
  gizmos.beginShape();
  for (PVector p : mouse)
    gizmos.vertex(p.x, p.y);
  gizmos.endShape(CLOSE);
  gizmos.popMatrix();

  gizmos.endDraw();
  image(system, 0, 0);
  image(gizmos, 0, 0);
}

PVector attract(Planet p) {
  PVector f = PVector.sub(sun, p.pos);
  float d = f.mag();
  f.normalize();
  float s = FAC_GRAV / (d*d);
  f.mult(s);
  return f;
}

PVector attractMass(Planet p) {
  float m = SUN_MASS * p.mass;
  float rsq = sq(dist(sun, p.pos));
  float q = m/rsq;
  return PVector.sub(sun, p.pos).normalize().mult(FAC_GRAV * q);
}

void updateNewPlanetColour() {
  newPlanetColour = colourFromMass(newPlanetHue, newPlanetMass);
}

color colourFromMass(float hue, float mass) {
  float angleRedux = (1.0 / 16.0) * PI ; //(reduction geddit)
  float colourAngle = (((PI / 2) - (2 * angleRedux)) * ((mass - MIN_PLANET_MASS)/(MAX_PLANET_MASS - MIN_PLANET_MASS))) + angleRedux;
  float colourRadius = 255 * ((-(sqrt(2)-1) * 16 * colourAngle * (colourAngle - (PI / 2))/(PI * PI)) + 1);
  float satDepMass = colourRadius * sin(colourAngle); //sat dependent on mass
  float valDepMass = colourRadius * cos(colourAngle); //val dependent on mass
  return color(hue, satDepMass, valDepMass);
}

void keyPressed() {
  if (key == CODED) {
    switch(keyCode) {
    case alternateButton:
      alternateAction = true;
      break;
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
    case 'p':
      showProperties = !showProperties;
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
    case 'S':
      String screenshotName = "/screenshots/" + year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2) + ".png";
      if (alternateAction)
        save(screenshotName);
      else
        system.save(screenshotName);
      break;
    }
  }
}

void keyReleased() {
  if (key == CODED) {
    switch(keyCode) {
    case alternateButton:
      alternateAction = false;
      break;
    }
  } else {
    switch(key) {
    }
  }
}

float dist(PVector v1, PVector v2) {
  return dist(v1.x, v1.y, v2.x, v2.y);
}
