class Planet {
  PVector pos;
  PVector vel;
  PVector acc;

  ArrayList<PVector> trail;

  float radius;
  float mass;
  color col;

  boolean onScreen = true;

  Planet(PVector p, PVector v, float m, float r, color c) {
    pos = p;
    vel = v.mult(FAC_NEWP);
    acc = new PVector(0, 0);
    mass = m;
    radius = r;
    col = c;
    trail = new ArrayList<PVector>();
    for (int i = 0; i < trailLength; i++) {
      trail.add(pos.copy());
    }
  }

  void applyForce(PVector f) {
    f.div(mass); //Do take the mass into account in F = m * a  ==>  a = F / m
    acc.add(f);
  }

  void update(float fac) {
    //Newtonian Physics Calculation -->
    vel.add(PVector.mult(acc, fac));
    pos.add(PVector.mult(vel, fac));
    acc.mult(0);
  }

  void render() {
    onScreen = pos.x > -width/2 && pos.x < width*1.5 && pos.y > -height/2 && pos.y < height*1.5;

    //Trail (Should always be rendered, even if planet is off screen) -->
    if (trailTracking) {
      if (simRunning && !simHalted)
        trailUpdate();
      system.strokeCap(SQUARE);
      system.noFill();
      system.beginShape();
      for (int i = 0; i < trail.size(); i++) {
        PVector pb = trail.get(i);
        system.stroke(col, map(i, 0, trail.size(), 0, 200));
        system.strokeWeight(map(i, 0, trail.size(), 0, radius /3));
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
      if (showProperties) {
        gizmos.noStroke();
        gizmos.fill(255);
        gizmos.textSize(TEXT_SIZE);
        gizmos.textAlign(LEFT, BOTTOM);
        gizmos.textLeading(TEXT_SIZE);
        gizmos.text("v:" + nfc(vel.mag(), 1) + "\nm:" + nfc(mass, 1) + "\nr:" + nfc(radius, 1), pos.x, pos.y);
      }
    }
  }

  void trailUpdate() {
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
}
