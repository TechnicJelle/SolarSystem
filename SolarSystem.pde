ArrayList<Planet> planets;

PVector sun;
final float SUN_RADIUS = 64;
final float SUN_MASS = 1500;

final float MIN_PLANET_RADIUS = 8;
final float MAX_PLANET_RADIUS = SUN_RADIUS * 2/3;

final float MIN_PLANET_MASS = 10;
final float MAX_PLANET_MASS = SUN_MASS * 2/3;

final float FAC_GRAV = 100;
final float FAC_NEWP = 0.1;

final float TEXT_SIZE = 20;

final int TRAIL_LENGTH = 100;

final int TIMESTEPS_PER_FRAME = 10;

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

boolean enableRoche = true;
boolean enablePtPPhysics = true;
boolean enableSOI = false;

boolean simHalted = false;

final int alternateButton = SHIFT; //could also use ALT, because alternate
boolean alternateAction = false;

//Settings -->
float facSimSpeedMod = 1.0;
boolean trailTracking = true;
boolean trailHQ = true;
boolean simRunning = true;
boolean showHeadingLine = false;
boolean showProperties = false;
boolean showUI = true;

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
  newPlanetVel = PVector.sub(newPlanetPos, new PVector(mouseX, mouseY));
  if (newPlanetPos.y < barPos) {
    if (mouseButton == LEFT) {
      //Add Planet -->
      if (dist(newPlanetPos, sun) > SUN_RADIUS && showUI) { //Not in sun & UI is on
        planets.add(new Planet(newPlanetPos, PVector.mult(newPlanetVel, FAC_NEWP), newPlanetMass, newPlanetRadius, newPlanetColour));
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

  //Planet physics -->
  if (!mousePressed && simRunning && !simHalted) {
    for (int t = 0; t < TIMESTEPS_PER_FRAME * facSimSpeedMod; t++) {
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        
        //Remove planets out of screen with v > escape velocity
        if (dist(p.pos, sun) < p.radius + SUN_RADIUS || p.vel.mag() >= sqrt(2 * FAC_GRAV * SUN_MASS / PVector.sub(sun, p.pos).mag()) && !p.onScreen)
          planets.remove(i);

        //roche limit
        if (dist(p.pos, sun) < 2.456 * SUN_RADIUS * pow((SUN_MASS * p.radius * p.radius * p.radius) / (p.mass * SUN_RADIUS * SUN_RADIUS * SUN_RADIUS), (1.0 / 3.0)) && enableRoche) {
          explode(p, i);
        }
               
        if (!enableSOI & !enablePtPPhysics) {
          p.applyForce(attractMass(p));          
        } else if (enableSOI){ //Sphere of Influence based physics
          int SOIindex = SOIbody(p);
          if (SOIindex == -1 || SOIindex == i) {
            p.applyForce(attractMass(p));
          } else {
            p.applyForce(attractMass(p, planets.get(SOIindex))); //force based on p2p
            p.applyForce(attractSun(p, planets.get(SOIindex))); //force to compensate relative motion of main body
          }
        }
        
        //Planet - Planet interactions
        if (enablePtPPhysics) {
          p.applyForce(attractMass(p));
          for (int z = planets.size() - 1; z >= 0; z--) {
            if (z != i) {   
              p.applyForce(attractMass(p, planets.get(z)));
            }
          }

          //Planets explode upon impact
          for (int z = planets.size() - 1; z >= 0; z--) {
            if (z != i && dist(p.pos, planets.get(z).pos) < (p.radius + planets.get(z).radius) / 2 && degrees(PVector.angleBetween(planets.get(z).vel, p.vel)) > 60 && p.mass < 10 * planets.get(z).mass && p.radius < 10 * planets.get(z).radius) {
              p.explodeMe = true;
            }
          }
        }
        p.update(1/float(TIMESTEPS_PER_FRAME));
      }
      
      while (containsExplode(planets)) {
        for (int z = planets.size() - 1; z >= 0; z--) {
          if (planets.get(z).explodeMe) {
            explode(planets.get(z), z);
          }
        }
      }
    }
  }

  //Sun -->
  system.noStroke();
  system.fill(32, 255, 255);
  system.circle(sun.x, sun.y, SUN_RADIUS *2);

  if (showUI) {
    if (frameCount > 1)
      gizmos.clear();
    gizmos.beginDraw();
    gizmos.colorMode(HSB);

    gizmos.noStroke();
    gizmos.fill(255);
    gizmos.textSize(TEXT_SIZE);
    gizmos.textLeading(TEXT_SIZE);
  }

  for (Planet p : planets) //Planets contain both system and gizmos graphics
    p.render();
  system.endDraw();

  if (showUI) {
    if (facSimSpeedMod > 0.96 && facSimSpeedMod < 1.04) {
      facSimSpeedMod = 1.0;
    } else {
      gizmos.textAlign(RIGHT, TOP);
      gizmos.text("x" + nfc(facSimSpeedMod, 1), width, 0);
    }

    if (showProperties) {
      gizmos.textAlign(CENTER, CENTER);
      gizmos.textLeading(TEXT_SIZE);
      gizmos.text("m:" + SUN_MASS + "\nr:" + SUN_RADIUS, sun.x, sun.y);
    }

    //Mass Changer Gizmo Pop-Up -->
    if (millis() - startMassChangeTime > 1000) //Hide again after a second
      showingNewMass = false;
    if (showingNewMass) {
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
          if (showProperties) {
            gizmos.textAlign(LEFT, BOTTOM);
            gizmos.text(nfc(newPlanetRadius, 1), newPlanetPos.x + newPlanetRadius *.7, newPlanetPos.y - newPlanetRadius *.7);
          }
          break;
        case LEFT: //Catapult Graphic
          if (dist(newPlanetPos, sun) > SUN_RADIUS) {
            //Relative End Coordinates -->
            newPlanetVel = PVector.sub(newPlanetPos, new PVector(mouseX, mouseY));
            gizmos.circle(newPlanetPos.x, newPlanetPos.y, newPlanetRadius *2);
            gizmos.strokeCap(ROUND);
            gizmos.line(newPlanetPos.x, newPlanetPos.y, newPlanetPos.x + FAC_NEWP*(newPlanetPos.x - mouseX), newPlanetPos.y + FAC_NEWP*(newPlanetPos.y - mouseY));
            if (showProperties) {
              gizmos.textAlign(LEFT, BOTTOM);
              gizmos.text(nfc(newPlanetVel.mag()*FAC_NEWP, 1), newPlanetPos.x + newPlanetRadius *.7, newPlanetPos.y - newPlanetRadius *.7);
            }
          }
          break;
        }
      } else if (newPlanetPos.y > barPos && mouseX < wd3csw && showUI) {
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
    gizmos.strokeWeight(colSegWidth);
    gizmos.strokeCap(SQUARE);
    for (float i = 0; i < wd3+1; i+=colSegWidth) {
      gizmos.stroke(map(i, 0, wd3, 0, 255), 255, 255, 200);
      gizmos.line(i + colSegWidth/2, barPos, i + colSegWidth/2, height);
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
  }

  image(system, 0, 0);
  if (showUI)
    image(gizmos, 0, 0);
  
  //3-body sphere of influence debug overlay  
  // SOIoverlay();  
}

PVector attract(Planet p) {
  PVector f = PVector.sub(sun, p.pos);
  float d = f.mag();
  f.normalize();
  float s = FAC_GRAV / (d*d);
  f.mult(s);
  return f;
}

//Force based on planet Q, but applied to P using P's mass
PVector attractSun(Planet p, Planet Q){
  float m = SUN_MASS * p.mass;
  float rsq = sq(dist(sun, Q.pos));
  float q = m/rsq;
  return PVector.sub(sun, p.pos).normalize().mult(FAC_GRAV * q);
}

PVector attractMass(Planet p) {
  float m = SUN_MASS * p.mass;
  float rsq = sq(dist(sun, p.pos));
  float q = m/rsq;
  return PVector.sub(sun, p.pos).normalize().mult(FAC_GRAV * q);
}

boolean containsExplode(ArrayList<Planet> q) {
  for (int z = q.size() - 1; z >= 0; z--) {
    if (q.get(z).explodeMe) {
      return true;
    }
  }
  return false;
}

PVector attractMass(Planet p, Planet o) {
  float d = dist(p.pos, o.pos);
  float m = o.mass * p.mass;

  if (d > p.radius + o.radius) {
    float rsq = sq(dist(o.pos, p.pos));
    float q = m/rsq;
    return PVector.sub(o.pos, p.pos).normalize().mult(FAC_GRAV * q);
  } else if (d > 2.0 * (p.radius + o.radius) / 3.0) {
    return new PVector(0, 0);
  } else {
    //float rsq = sq(sq(dist(o.pos, p.pos)));
    //float q = m/rsq; 
    float q = 0;
    return PVector.sub(o.pos, p.pos).normalize().mult(FAC_GRAV * -q);
  }
}

boolean roche(Planet p, Planet M) {
  return dist(p.pos, M.pos) < 2.456 * M.radius * pow((M.mass / (M.radius * M.radius * M.radius)) / (p.mass / (p.radius * p.radius * p.radius)), (1.0 / 3.0));
}

void explode(Planet p, int i) {
  int pieces = (int)random(2, 9); //possible amounts of debris
  float newMassTotal = 0;
  float newAreaTotal = 0;
  PVector totalError = new PVector();
  float[] newMasses = new float[pieces];
  float[] newRadii = new float[pieces];
  float[] newVelMags = new float[pieces];
  PVector[] newVels = new PVector[pieces];
  for (int j=0; j < pieces; j++) {
    newMasses[j] = random(1.0, 100.0);
    newMassTotal += newMasses[j];
    newRadii[j] = random(1.0, 100.0);
    newAreaTotal += sq(newRadii[j]);
    newVelMags[j] = random(1.0, 10.0); //min and max explosion speed
  }
  float massFac = p.mass / newMassTotal;
  float areaFac = sq(p.radius) / newAreaTotal;
  newVels[pieces-1] = new PVector(0.0, 0.0);
  for (int j=0; j < pieces; j++) {
    newMasses[j] *= massFac;
    newRadii[j] *= sqrt(areaFac);
    newVels[j] = PVector.random2D().normalize().mult(newMasses[j] * newVelMags[j]);
    totalError.sub(newVels[j]);
    newVels[j].div(newMasses[j]);
  }

  for (int j=0; j < pieces; j++) {
    newVels[j].sub(PVector.div(totalError, newMasses[j] * (pieces + 1)));
  }
  for (int j=0; j < pieces; j++) {
    PVector newVel = PVector.add(PVector.mult(newVels[j], 0.5), p.vel);
    float spawningLimit = p.radius - newRadii[j];
    PVector newPos = new PVector(random(-spawningLimit, spawningLimit), random(-spawningLimit, spawningLimit)).add(p.pos);
    if (newRadii[j] >= MIN_PLANET_RADIUS/2) {
      planets.add(new Planet(newPos, newVel, newMasses[j], newRadii[j], colourFromMass(hue(p.col), newMasses[j])));
    }
  }

  if (i < planets.size()) {
    planets.remove(i);
  }
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
    case '=':
    case '+':
      if (alternateAction)
        facSimSpeedMod = constrain(facSimSpeedMod + 0.1, 0.1, 5);
      else        
        facSimSpeedMod = constrain(facSimSpeedMod + 0.5, 0.5, 5);
      break;
    case '-':
    case '_':
      if (alternateAction)
        facSimSpeedMod = constrain(facSimSpeedMod - 0.1, 0.1, 5);
      else
        facSimSpeedMod = constrain(facSimSpeedMod - 0.5, 0.5, 5);
      break;
    case ' ':
      simRunning = !simRunning;
      break;
    case 't':
    case 'T':
      trailTracking = !trailTracking;
      break;
    case 'h':
    case 'H':
      showHeadingLine = !showHeadingLine;
      break;
    case 'p':
    case 'P':
      showProperties = !showProperties;
      break;
    case 'u':
    case 'U':
      showUI = !showUI;
      break;
    case 'q':
    case 'Q':
      trailHQ = !trailHQ;
      break;
    case 'x': //remove a hovered over planet
    case 'X':
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(mouseX, mouseY, p.pos.x, p.pos.y) < p.radius) {
          planets.remove(i);
        }
      }
      break;
    case 'f':
    case 'F':
      if(enablePtPPhysics){
        enablePtPPhysics = !enablePtPPhysics;
        enableSOI = !enableSOI;
      } else if(enableSOI) {
        enableSOI = !enableSOI;
      } else {
        enablePtPPhysics = !enablePtPPhysics;
      }
      break;
    case 'k':
    case 'K':
    for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(mouseX, mouseY, p.pos.x, p.pos.y) < p.radius) {
          setKeplerOrbit(planets.get(i));
        }
      }
      break;
    case 'r':
    case 'R':
      enableRoche = !enableRoche;
      break;
    case 'z': //remove offscreen planets
    case 'Z':
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (!p.onScreen) {
          planets.remove(i);
        }
      }
      break;
    case 'd': //destroy planet creating multiple smaller ones
    case 'D':
      for (int i = planets.size() - 1; i >= 0; i--) {
        Planet p = planets.get(i);
        if (dist(mouseX, mouseY, p.pos.x, p.pos.y) < p.radius) {
          explode(p, i);
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

//Gravitational force
float F_energy(float x, float y, Planet P) { 
  return FAC_GRAV * P.mass / distance(x, y, P);
}

//influence of P on Q
float F_energy(Planet Q, Planet P) { 
  return FAC_GRAV * P.mass / (dist(P.pos, Q.pos) * dist(P.pos, Q.pos));
}

//square of the distance between x,y and p
float distance(float x, float y, Planet P) {
  return (x - P.pos.x) * (x - P.pos.x) + (y - P.pos.y) * (y - P.pos.y);
}

//Find body with most influence on P
int SOIbody(Planet P) {
  int index = 0;
  float largest = -1;
  if (planets.size() > 1) {
    for (int i = 0; i < planets.size(); i++){
      if (F_energy(P, planets.get(i)) > largest){
        if (planets.get(i) != P){ 
          largest = F_energy(P, planets.get(i));
          index = i;
        }
      }
    }
  }
  if (FAC_GRAV * SUN_MASS / ((P.pos.x-width/2) * (P.pos.x-width/2) + (P.pos.y-height/2) * (P.pos.y-height/2)) > largest){
    return -1; 
  } else {
    return index;
  }
}

//SOI debug overlay
void SOIoverlay() {  
  float step = 3; //overlay density
  if (planets.size() > 1) {
    for (int i = 0; i < width; i += step) {
      for (int j = 0; j < height; j += step) {
        float S_energy = FAC_GRAV * SUN_MASS / ((i-width/2) * (i-width/2) + (j-height/2) * (j-height/2));
        if (F_energy(i, j, planets.get(1)) >= F_energy(i, j, planets.get(0)) && F_energy(i, j, planets.get(1)) > S_energy) {
          set(i, j, color(255, 255, 255));
        } else if (F_energy(i, j, planets.get(0)) >= F_energy(i, j, planets.get(1)) && F_energy(i, j, planets.get(0)) > S_energy) {
          set(i, j, color(150, 255, 255));
        } else {
          set(i, j, color(50, 255, 255));
        }
      }
    }
  }
}

//Kerlerian circle orbit around body with most influence
void setKeplerOrbit(Planet P){
  int index = SOIbody(P);
  float velocity;
  float angle;
  
  if (index == -1){
    velocity = sqrt(FAC_GRAV * SUN_MASS / sqrt(distance(width/2, height/2, P)));
    angle = PI - atan((P.pos.y-height/2) / (P.pos.x-width/2));
  
    if (P.pos.x > width/2 && P.pos.y > height/2){
      angle += PI;
    } else if(P.pos.x > width/2 && P.pos.y < height/2) {
      angle -= PI;  
    }
  } else {
    velocity = sqrt(FAC_GRAV * planets.get(index).mass / dist(P.pos, planets.get(index).pos));
    angle = PI - atan((P.pos.y - planets.get(index).pos.y) / (P.pos.x - planets.get(index).pos.x));
    
    if (P.pos.x > planets.get(index).pos.x && P.pos.y > planets.get(index).pos.y){
      angle += PI;
    } else if(P.pos.x > planets.get(index).pos.x && P.pos.y < planets.get(index).pos.y) {
      angle -= PI;  
    }
  }
  
  PVector v = new PVector(-sin(angle) * velocity, -cos(angle) * velocity);
  
  if(index == -1){
    P.vel = v;
  } else {  
    P.vel = v.add(planets.get(index).vel);
  }
}
