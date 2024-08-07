import java.util.Iterator;
import java.util.ArrayList;

ArrayList<Star> stars;
ArrayList<Meteor> meteors;
ArrayList<Debris> debrisList; // List to handle debris from shattered meteors
int lives = 3;
float shakeAmount = 0;
boolean gameStarted = false;
int meteorInterval = 2000; // Start with 2 seconds between meteor spawns
int lastMeteorTime;
int numStars = 800;
int numMeteors = 5;
int screenFlashOpacity = 0;

int destroyedMeteors = 0; // Counter to track the number of destroyed meteors

void setup() {
  size(1920, 1080);
  stars = new ArrayList<Star>();
  meteors = new ArrayList<Meteor>();
  debrisList = new ArrayList<Debris>();
  for (int i = 0; i < numStars; i++) {
    stars.add(new Star());
  }
}

void draw() {
  background(0);
  if (shakeAmount > 0) {
    translate(random(-shakeAmount, shakeAmount), random(-shakeAmount, shakeAmount));
    shakeAmount *= 0.9;
  }
  translate(width / 2, height / 2);
 
  for (Star star : stars) {
    star.update();
    star.show();
  }
 
  if (gameStarted) {
    if (millis() - lastMeteorTime > meteorInterval && meteors.size() < numMeteors) {
      meteors.add(new Meteor(false));
      lastMeteorTime = millis();
    }
    Iterator<Meteor> it = meteors.iterator();
    while (it.hasNext()) {
      Meteor meteor = it.next();
      meteor.update();
      if (!meteor.isActive) {
        it.remove();
        destroyedMeteors++; // Increment the destroyed meteors counter
      } else {
        meteor.show();
      }
    }

    checkGameOver();
    displayLives();
  } else {
    displayStartScreen();
  }

  // Handle screen flash when a life is lost
  if (screenFlashOpacity > 0) {
    fill(255, 0, 0, screenFlashOpacity);
    rect(-width / 2, -height / 2, width, height);
    screenFlashOpacity -= 15;
  }
}

void mousePressed() {
  if (gameStarted) {
    boolean clicked = false;
    for (Meteor meteor : meteors) {
      if (meteor.checkClick(mouseX - width / 2, mouseY - height / 2)) {
        clicked = true;
        break;
      }
    }
    if (!clicked && dist(mouseX, mouseY, width / 2, height / 2) < 50) {
      startGame();
    }
  } else {
    if (dist(mouseX, mouseY, width / 2, height / 2) < 50) {
      startGame();
    }
  }
}

void startGame() {
  gameStarted = true;
  lives = 3;
  meteors.clear();
  debrisList.clear();
  lastMeteorTime = millis();
  destroyedMeteors = 0; // Reset destroyed meteors counter
}

void checkGameOver() {
  if (lives <= 0) {
    gameStarted = false;
  }
}

void displayLives() {
  textSize(32); // Increase text size
  fill(255);
  text("Lives: " + lives, 10, -height / 2 + 50); // Adjust position
  textSize(24); // Increase text size for destroyed meteors counter
  fill(255);
  text("Destroyed Meteors: " + destroyedMeteors, 10, -height / 2 + 100); // Display destroyed meteors counter
}

void displayStartScreen() {
  fill(0, 0, 255); // Blue text color
  textSize(60);
  textAlign(CENTER);
  text("Orbit Smashers", 0, -50); // Title
  fill(255, 0, 0); // Red text color
  textSize(20);
  text("Start", -20, 5); // Start button
}

class Star {
  float x, y, z, pz;

  Star() {
    x = random(-width, width);
    y = random(-height, height);
    z = random(width);
    pz = z;
  }

  void update() {
    z -= 20;
    if (z < 1) {
      z = width;
      x = random(-width, width);
      y = random(-height, height);
      pz = z;
    }
  }

  void show() {
    fill(255);
    noStroke();
    float sx = map(x / z, 0, 1, 0, width);
    float sy = map(y / z, 0, 1, 0, height);
    float r = map(z, 0, width, 16, 0);
    ellipse(sx, sy, r, r);
  }
}

class Meteor {
  float x, y, z, pz;
  boolean isActive;
  float size = 50;
  float opacity = 255;
  boolean isShattering = false;

  Meteor(boolean startInactive) {
    if (!startInactive) {
      resetMeteor();
    } else {
      isActive = false;
    }
  }

  void resetMeteor() {
    x = random(-width/1.5, width/1.5);
    y = random(-height/1.5, height/1.5);
    z = random(width * 2, width * 3);
    pz = z;
    isActive = true;
    size = 50; // Start with a reasonable size for visibility
    opacity = 255;
  }

  void update() {
    if (!isActive) return;

    if (!isShattering) {
      z -= 50; // Slower movement towards the player
      size += 2; // Slower growth rate
      if (z < 50 && !isShattering) {
        isActive = false;
        lives--;
        shakeAmount = 20;
        screenFlashOpacity = 150; // Trigger red screen flash
      }
    } else {
      // Shatter logic: pieces falling apart
      if (opacity > 0 && size > 0) {
        opacity -= 5;
        size -= 0.5;
      } else {
        isActive = false;
      }
    }
  }

  void show() {
    if (isActive) {
      fill(60, 60, 60, opacity); // Dark gray color for meteors
      noStroke();
      float sx = map(x / z, 0, 1, 0, width);
      float sy = map(y / z, 0, 1, 0, height);
      ellipse(sx, sy, size, size);
    }
  }

  boolean checkClick(float mouseX, float mouseY) {
    float sx = map(x / z, 0, 1, 0, width);
    float sy = map(y / z, 0, 1, 0, height);
    if (dist(mouseX, mouseY, sx, sy) < size / 2) {
      isShattering = true; // Start shattering on click
      createDebris(sx, sy);
      return true;
    }
    return false;
  }

  void createDebris(float sx, float sy) {
    for (int i = 0; i < 5; i++) {
      float angle = random(TWO_PI);
      float speed = random(2, 5);
      debrisList.add(new Debris(sx, sy, cos(angle) * speed, sin(angle) * speed, size / 3));
    }
  }
}

class Debris {
  float x, y, vx, vy, size;
  int lifespan = 255;

  Debris(float x, float y, float vx, float vy, float size) {
    this.x = x;
    this.y = y;
    this.vx = vx;
    this.vy = vy;
    this.size = size;
  }

  void update() {
    x += vx;
    y += vy;
    lifespan -= 5;
  }

  void show() {
    fill(150, 150, 150, lifespan);
    noStroke();
    ellipse(x, y, size, size);
  }
}
