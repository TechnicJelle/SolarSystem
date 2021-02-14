class Planet {
  PVector pos;
  PVector vel;
  PVector acc;

  ArrayList<PVector> trail;

  float radius = 32;
  color col = color(255, 128, 0);

  boolean onScreen = true;

  Planet(float x, float y, float vx, float vy, float r, color c) {
    pos = new PVector(x, y);
    vel = new PVector(vx, vy).mult(FAC_NEWP);
    acc = new PVector(0, 0);
    radius = r;
    col = c;
    trail = new ArrayList<PVector>();
    for (int i = 0; i < trailLength; i++) {
      trail.add(pos.copy());
    }
  }

  void applyForce(PVector f) {
    acc.add(f);
  }

  void update() {
    //Newtonian Physics Calculation -->
    vel.add(acc);
    pos.add(vel);
    acc.mult(0);

    onScreen = pos.x > -width/2 && pos.x < width*1.5 && pos.y > -height/2 && pos.y < height*1.5;

    //Trail Variable Sampling -->
    if (trailTracking) {
      if (onScreen) {
        if (trailHQ) {
          trail.add(pos.copy());
        } else {
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
      }

      //Trail Cleanup -->
      while (trail.size() > trailLength) {
        trail.remove(0);
      }
    }
  }

  void render() {
    //Trail (Should always be rendered, even if planet is off screen) -->
    if (trailTracking) {
      system.strokeCap(SQUARE);
      system.noFill();
      system.beginShape();
      for (int i = 0; i < trail.size(); i++) {
        PVector pb = trail.get(i);
        system.stroke(col, map(i, 0, trail.size(), 0, 255));
        system.strokeWeight(map(i, 0, trail.size(), 0, 5));
        system.curveVertex(pb.x, pb.y);
      }
      system.endShape();
    }

    if (onScreen) {
      //Planet -->
      system.noStroke();
      system.fill(col);
      system.circle(pos.x, pos.y, radius *2);

      //Heading Vector Line -->
      if (showHeadingLine) {
        gizmos.stroke(255);
        gizmos.strokeWeight(3);
        gizmos.strokeCap(ROUND);
        gizmos.line(pos.x, pos.y, pos.x + vel.x, pos.y + vel.y);
      }

      //Velocity Text -->
      if (showVelocity) {
        gizmos.noStroke();
        gizmos.fill(255);
        gizmos.textSize(24);
        gizmos.text(vel.mag(), pos.x, pos.y + 32);
      }
    }
  }
}
