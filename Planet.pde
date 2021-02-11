class Planet {
  PVector pos;
  PVector vel;
  PVector acc;

  ArrayList<PVector> trail;

  color col = color(255, 128, 0);

  Planet(float x, float y, float vx, float vy, color c) {
    pos = new PVector(x, y);
    vel = new PVector(vx, vy).mult(FAC_NEWP);
    acc = new PVector(0, 0);
    col = c;
    trail = new ArrayList<PVector>();
  }

  void applyForce(PVector f) {
    acc.add(f);
  }

  void update() {
    //Newtonian Physics Calculation --
    vel.add(acc);
    pos.add(vel);
    acc.mult(0);
    
    //Trail Variable Sampling -->
    if (pos.x > -width/2 && pos.x < width*1.5 && pos.y > -height/2 && pos.y < height*1.5) {
      if (vel.mag() > 20) {
        trail.add(pos.copy());
      } else if (vel.mag() < 20 && vel.mag() > 15) {
        if (frameCount % 4 == 0) {
          trail.add(pos.copy());
        }
      } else if (vel.mag() < 15 && vel.mag() > 10) {
        if (frameCount % 6 == 0) {
          trail.add(pos.copy());
        }
      } else if (vel.mag() < 10 && vel.mag() > 5) {
        if (frameCount % 7 == 0) {
          trail.add(pos.copy());
        }
      } else if (vel.mag() < 5) {
        if (frameCount % 8 == 0) {
          trail.add(pos.copy());
        }
      }
    }
    
    //Trail Cleanup -->
    if (trail.size() > 100) {
      trail.remove(0);
    }
  }

  void render() {
    //Planet -->
    //stroke(128);
    //strokeWeight(1);
    noStroke();
    fill(col);
    circle(pos.x, pos.y, DIAM_PLA);

    //Heading Vector Line -->
    //strokeWeight(3);
    //strokeCap(ROUND);
    //line(pos.x, pos.y, pos.x + vel.x, pos.y + vel.y);

    //Trail -->
    strokeCap(SQUARE);
    for (int i = 1; i < trail.size(); i++) {
      PVector pb = trail.get(i);
      PVector pa = trail.get(i-1);
      stroke(col, map(i, 0, trail.size(), 0, 255));
      strokeWeight(map(i, 0, trail.size(), 0, 5));
      line(pb.x, pb.y, pa.x, pa.y);
    }

    //Velocity Text -->
    noStroke();
    fill(255);
    textSize(32);
    text(vel.mag(), pos.x, pos.y + 32);
  }
}






















