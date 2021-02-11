import android.widget.Toast;
import android.app.Activity;
Activity act;

PVector sun;

ArrayList<Planet> planets;

final float FAC_GRAV = 100000;
final float FAC_NEWP = 0.1;

final float DIAM_SUN = 128;
final float DIAM_PLA = 32;
final float DIAM_NPL = 64;

float barHeight;
final float barTouch = 48;
color pCol;

void setup() {
  fullScreen();
  act = this.getActivity();
  sun = new PVector(width/2, height/2);
  planets = new ArrayList<Planet>();
  showToast("Swipe to spawn a new planet!");
  barHeight = height - height/16;
  pCol = color(255, 128, 0);
}

void draw() {
  background(10);

  //Planets -->
  for (int i = planets.size() - 1; i >= 0; i--) {
    Planet p = planets.get(i);
    if (!isTouching()) {
      //p.applyForce(PVector.sub(sun, p.pos).mult(FAC_GRAV));
      p.applyForce(attract(p));
      p.update();
    }
    if (dist(p.pos.x, p.pos.y, sun.x, sun.y) < DIAM_SUN/2) {
      planets.remove(i);
    }
    p.render();
  }

  //Sun -->
  stroke(255);
  strokeWeight(1);
  fill(255, 255, 0);
  circle(sun.x, sun.y, DIAM_SUN);

  //Touch Actions -->
  if (isTouching() && nPy < barHeight) {
    //Catapult Graphic
    stroke(255);
    strokeWeight(4);
    strokeCap(ROUND);
    noFill();
    circle(nPx, nPy, DIAM_NPL);
    line(nPx, nPy, nPx + FAC_NEWP*(nPx - mouseX), nPy + FAC_NEWP*(nPy - mouseY));
  } else if (isTouching() && movingBar) {
    barHeight = mouseY;
  } else if (isTouching() && nPy > barHeight && mouseX < width/3) {
    //Colour Picker
    colorMode(HSB);
    pCol = color(map(mouseX, 0, width/3, 0, 255), 255, 255);
    stroke(128);
    strokeWeight(10);
    fill(pCol);
    rect(mouseX, barHeight - 32, width/6, -width/6, 20);
    colorMode(RGB);
  } 

  //Colour Picker Render -->
  final float colSegWidth = 10;
  strokeWeight(colSegWidth);
  strokeCap(SQUARE);
  colorMode(HSB);
  for (float i = 0; i < width/3; i+=colSegWidth) {
    stroke(map(i, 0, width/3, 0, 225), 255, 255, 200);
    line(i, barHeight+1, i, height);
  }
  colorMode(RGB);

  //ToolBar Grabby Render -->
  noStroke();
  fill(128, 64);
  rect(0, barHeight, width, barTouch);

  //ToolBar Render -->
  stroke(255);
  //if(nPy > barHeight && nPy < barHeight+barTouch) {
  if (movingBar) {
    strokeWeight(10);
  } else {
    strokeWeight(3);
  }
  strokeCap(SQUARE);
  line(0, barHeight, width, barHeight);

  fpsCount();
}

PVector attract(Planet p) {
  PVector f = PVector.sub(sun, p.pos);
  float d = f.mag();
  f.normalize();
  float s = FAC_GRAV / (d*d);
  f.mult(s);
  //println(f);
  return f;
}

boolean movingBar = false;

float nPx, nPy;
float nPvx, nPvy;
void mousePressed() {
  if (mouseY<barHeight) {
    //Start Coordinates -->
    nPx = mouseX;
    nPy = mouseY;
  } else if (mouseY > barHeight && mouseY < barHeight + barTouch) {
    //Tap in bar
    //pCol =color(156,255,255);
    //showToast("!");
    movingBar = true;
  }
}

void mouseReleased() {
  if (nPy<barHeight) {
    //End Coordinates -->
    nPvx = nPx - mouseX;
    nPvy = nPy - mouseY;
    //Add Planet -->
    planets.add(new Planet(nPx, nPy, nPvx, nPvy, pCol));
  }
  //Reset to Prevent ToolBar Interference -->
  nPy = height;
  movingBar = false;
}

boolean isTouching() {
  return touches.length > 0;
}

float txtSize = 64;
void fpsCount() {
  pushStyle();
  String fps = str(round(frameRate));
  noStroke();
  fill(0);
  rect(10, 10, 2* textWidth(fps), txtSize*0.8);
  textSize(txtSize);
  textAlign(LEFT, TOP);
  fill(255, 255, 0);
  text(fps, 10, 10);
}

void circle(float x, float y, float d) {
  ellipse(x, y, d, d);
}

void showToast(final String message) {
  runOnUiThread(new Runnable() {
    public void run() {
      android.widget.Toast.makeText(act.getApplicationContext(), message, android.widget.Toast.LENGTH_LONG).show();
    }
  }
  );
}

















