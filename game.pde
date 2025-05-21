// Game states
final int START_SCREEN = 0;
final int GAME_SCREEN = 1;
final int UPGRADE_SCREEN = 2;
final int GAME_OVER = 3;
final int YOU_WIN = 4;
int gameState = START_SCREEN;

// Player variables
String playerName = "";
boolean nameEntered = false;
PVector playerPos;
int playerLives = 3;
int playerMaxLives = 3;
int playerDamage = 1;
float fireRate = 0.5; // seconds
float lastShotTime = 0;
boolean canShoot = true;
ArrayList<Bullet> bullets = new ArrayList<Bullet>();
float bulletSize = 5;
boolean freedomX = false;
boolean freedomY = false;
float playerSpeed = 2;
boolean doubleShot = false;

// Enemy variables
ArrayList<Enemy> enemies = new ArrayList<Enemy>();
int currentRound = 1;
int enemiesToSpawn = 0;
int enemiesAlive = 0;
boolean roundInProgress = false;
float enemySpeed = 1.5;
float enemySpeedMultiplier = 1.0;
boolean roundComplete = false;
int roundCompleteTime = 0;

// Upgrade variables
ArrayList<Upgrade> availableUpgrades = new ArrayList<Upgrade>();
ArrayList<Upgrade> selectedUpgrades = new ArrayList<Upgrade>();
Upgrade[] currentUpgradeOptions = new Upgrade[3];
int selectedUpgradeIndex = -1;
int upgradeConfirmTime = 0;
boolean upgradeSelected = false;
int nextRoundTime = 0;
boolean countingDown = false;
int countdown = 3;

// UI variables
PFont gameFont;
boolean typing = false;
String roundText = "";
int roundTextDisplayTime = 0;

void setup() {
  size(800, 600);
  playerPos = new PVector(width/2, height/2);
  gameFont = createFont("Arial", 16);
  textFont(gameFont);
  
  // Initialize all upgrades
  availableUpgrades.add(new Upgrade("VIDA EXTRA", "+1 Vida", 3));
  availableUpgrades.add(new Upgrade("DANO EXTRA", "+1 Dano", 3));
  availableUpgrades.add(new Upgrade("VELOCIDADE DE ATAQUE", "Vel. de Ataque", 3));
  availableUpgrades.add(new Upgrade("LIBERDADE X", "Mov. horizontal", 1));
  availableUpgrades.add(new Upgrade("LIBERDADE Y", "Mov. vertical", 1));
  availableUpgrades.add(new Upgrade("ATAQUE DUPLO", "Dispara 2 disparo", 1));
  availableUpgrades.add(new Upgrade("VELOCIDADE", "Vel. de movimento", 3));
  availableUpgrades.add(new Upgrade("DISPARO AUMENTADO", "+ Tam. do disparo", 3));
}

void draw() {
  background(0);
  
  switch(gameState) {
    case START_SCREEN:
      drawStartScreen();
      break;
    case GAME_SCREEN:
      drawGameScreen();
      break;
    case UPGRADE_SCREEN:
      drawUpgradeScreen();
      break;
    case GAME_OVER:
      drawGameOverScreen();
      break;
    case YOU_WIN:
      drawYouWinScreen();
      break;
  }
}

void drawStartScreen() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  text("ROGUE-LIKE GAME", width/2, height/4);
  
  textSize(24);
  text("Digite seu nome:", width/2, height/2 - 30);
  
  // Input box
  stroke(255);
  noFill();
  rect(width/2 - 150, height/2, 300, 40);
  
  // Display entered text
  fill(255);
  textAlign(LEFT, CENTER);
  text(playerName, width/2 - 140, height/2 + 20);
  
  // Start button
  fill(nameEntered ? color(0, 255, 0) : color(100));
  rect(width/2 - 75, height/2 + 80, 150, 50);
  fill(0);
  textAlign(CENTER, CENTER);
  text("INICIAR", width/2, height/2 + 105);
  
  // Cursor blink
  if (typing && frameCount % 60 < 30) {
    float cursorX = width/2 - 140 + textWidth(playerName);
    line(cursorX, height/2 + 10, cursorX, height/2 + 30);
  }
}

void drawGameScreen() {
  // Draw player
  fill(0, 0, 255);
  ellipse(playerPos.x, playerPos.y, 30, 30);
  
  // Draw player lives
  for (int i = 0; i < playerMaxLives; i++) {
    if (i < playerLives) {
      fill(255, 0, 0);
    } else {
      fill(100);
    }
    rect(20 + i * 30, 20, 20, 20);
  }
  
  // Draw round info
  fill(255);
  textAlign(LEFT, TOP);
  text("Rodada: " + currentRound, 20, 50);
  
  // Draw bullets
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet b = bullets.get(i);
    b.update();
    b.display();
    
    // Remove bullets that are off screen
    if (b.isOffScreen()) {
      bullets.remove(i);
    }
  }
  
  // Spawn enemies if round is in progress
  if (roundInProgress) {
    if (enemiesToSpawn > 0 && frameCount % 30 == 0) {
      spawnEnemy();
      enemiesToSpawn--;
    }
    
    // Update and draw enemies
    for (int i = enemies.size() - 1; i >= 0; i--) {
      Enemy e = enemies.get(i);
      e.update();
      e.display();
      
      // Check collision with player
      if (e.collidesWithPlayer()) {
        playerLives--;
        enemies.remove(i);
        enemiesAlive--;
        
        if (playerLives <= 0) {
          gameState = GAME_OVER;
        }
      }
      
      // Check collision with bullets
      for (int j = bullets.size() - 1; j >= 0; j--) {
        Bullet b = bullets.get(j);
        if (e.collidesWith(b)) {
          e.takeDamage(playerDamage);
          bullets.remove(j);
          
          if (e.health <= 0) {
            enemies.remove(i);
            enemiesAlive--;
            break;
          }
        }
      }
    }
    
    // Check if round is complete
    if (enemiesToSpawn == 0 && enemiesAlive == 0 && roundInProgress) {
      roundComplete();
    }
  }
  
  // Display round complete text
  if (roundText != "" && millis() - roundTextDisplayTime < 2000) {
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    text(roundText, width/2, height/2);
    textSize(16);
  }
  
  // Countdown to next round
  if (countingDown) {
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("Próxima rodada em: " + countdown, width/2, height/2 + 50);
    
    if (millis() - nextRoundTime > 1000) {
      nextRoundTime = millis();
      countdown--;
      
      if (countdown == 0) {
        countingDown = false;
        startRound();
      }
    }
  }
}

void drawUpgradeScreen() {
  // Semi-transparent background
  fill(0, 200);
  rect(0, 0, width, height);
  
  // Upgrade selection box
  fill(50);
  stroke(255);
  rect(width/2 - 350, height/2 - 150, 700, 300);
  
  // Title
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(24);
  text("ESCOLHA SEU UPGRADE", width/2, height/2 - 120);
  
  // Display upgrade options
  for (int i = 0; i < currentUpgradeOptions.length; i++) {
    if (currentUpgradeOptions[i] != null) {
      // Highlight selected upgrade
      if (i == selectedUpgradeIndex) {
        fill(100);
      } else {
        fill(70);
      }
      rect(width/2 - 320 + i * 220, height/2 - 80, 200, 150);
      
      // Upgrade info
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(18);
      text(currentUpgradeOptions[i].name, width/2 - 320 + i * 220 + 100, height/2 - 60);
      textSize(14);
      text(currentUpgradeOptions[i].description, width/2 - 320 + i * 220 + 100, height/2 - 30);
      
      // Display how many times it can be upgraded
      if (currentUpgradeOptions[i].maxTimes > 1) {
        text("(" + currentUpgradeOptions[i].timesSelected + "/" + currentUpgradeOptions[i].maxTimes + ")", 
             width/2 - 320 + i * 220 + 100, height/2);
      } else {
        text("(Único)", width/2 - 320 + i * 220 + 100, height/2);
      }
    }
  }
  
  // Confirm button (only enabled when an upgrade is selected)
  if (selectedUpgradeIndex != -1) {
    fill(0, 255, 0);
  } else {
    fill(100);
  }
  rect(width/2 - 75, height/2 + 100, 150, 40);
  fill(0);
  textAlign(CENTER, CENTER);
  text("CONFIRMAR", width/2, height/2 + 120);
}

void drawGameOverScreen() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  text("GAME OVER", width/2, height/3);
  
  textSize(24);
  text("Jogador: " + playerName, width/2, height/2);
  text("Rodada alcançada: " + currentRound, width/2, height/2 + 40);
  
  // Play again button
  fill(0, 255, 0);
  rect(width/2 - 100, height/2 + 100, 200, 50);
  fill(0);
  text("Jogar Novamente", width/2, height/2 + 125);
}

void drawYouWinScreen() {
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  text("VITÓRIA!", width/2, height/3);
  
  textSize(24);
  text("Jogador: " + playerName, width/2, height/2);
  text("Rodada alcançada: " + currentRound, width/2, height/2 + 40);
  
  // Play again button
  fill(0, 255, 0);
  rect(width/2 - 100, height/2 + 100, 200, 50);
  fill(0);
  text("Jogar Novamente", width/2, height/2 + 125);
}

void mousePressed() {
  switch(gameState) {
    case START_SCREEN:
      // Check if clicked on input box
      if (mouseX > width/2 - 150 && mouseX < width/2 + 150 && 
          mouseY > height/2 && mouseY < height/2 + 40) {
        typing = true;
      } else {
        typing = false;
      }
      
      // Check if clicked on start button
      if (mouseX > width/2 - 75 && mouseX < width/2 + 75 && 
          mouseY > height/2 + 80 && mouseY < height/2 + 130 && nameEntered) {
        gameState = GAME_SCREEN;
        startRound();
      }
      break;
      
    case GAME_SCREEN:
      // Shooting handled in mouseReleased to allow for better control
      break;
      
    case UPGRADE_SCREEN:
      // Check if clicked on an upgrade option
      for (int i = 0; i < currentUpgradeOptions.length; i++) {
        if (currentUpgradeOptions[i] != null && 
            mouseX > width/2 - 320 + i * 220 && mouseX < width/2 - 320 + i * 220 + 200 &&
            mouseY > height/2 - 80 && mouseY < height/2 + 70) {
          selectedUpgradeIndex = i;
        }
      }
      
      // Check if clicked on confirm button
      if (selectedUpgradeIndex != -1 && 
          mouseX > width/2 - 75 && mouseX < width/2 + 75 &&
          mouseY > height/2 + 100 && mouseY < height/2 + 140) {
        applyUpgrade(currentUpgradeOptions[selectedUpgradeIndex]);
        upgradeSelected = true;
        upgradeConfirmTime = millis();
      }
      break;
      
    case GAME_OVER:
    case YOU_WIN:
      // Check if clicked on play again button
      if (mouseX > width/2 - 100 && mouseX < width/2 + 100 &&
          mouseY > height/2 + 100 && mouseY < height/2 + 150) {
        resetGame();
      }
      break;
  }
}

void mouseReleased() {
  if (gameState == GAME_SCREEN && roundInProgress && canShoot) {
    shoot();
  }
}

void keyPressed() {
  if (gameState == START_SCREEN && typing) {
    if (key == BACKSPACE && playerName.length() > 0) {
      playerName = playerName.substring(0, playerName.length() - 1);
    } else if (key == ENTER || key == RETURN) {
      typing = false;
      nameEntered = playerName.length() > 0;
    } else if (key != CODED && key != BACKSPACE && key != DELETE && key != ENTER && key != RETURN) {
      playerName += key;
      nameEntered = playerName.length() > 0;
    }
  }
  
  // Player movement when freedoms are unlocked
  if (gameState == GAME_SCREEN && roundInProgress) {
    if (freedomX) {
      if (keyCode == LEFT || key == 'a' || key == 'A') {
        playerPos.x = max(15, playerPos.x - playerSpeed);
      }
      if (keyCode == RIGHT || key == 'd' || key == 'D') {
        playerPos.x = min(width - 15, playerPos.x + playerSpeed);
      }
    }
    
    if (freedomY) {
      if (keyCode == UP || key == 'w' || key == 'W') {
        playerPos.y = max(15, playerPos.y - playerSpeed);
      }
      if (keyCode == DOWN || key == 's' || key == 'S') {
        playerPos.y = min(height - 15, playerPos.y + playerSpeed);
      }
    }
  }
}

void shoot() {
  if (millis() - lastShotTime > fireRate * 1000) {
    PVector mousePos = new PVector(mouseX, mouseY);
    PVector direction = PVector.sub(mousePos, playerPos).normalize();
    
    bullets.add(new Bullet(playerPos.x, playerPos.y, direction.x, direction.y));
    
    if (doubleShot) {
      // Add a second bullet slightly offset
      PVector offsetDirection = direction.copy().rotate(PI/12);
      bullets.add(new Bullet(playerPos.x, playerPos.y, offsetDirection.x, offsetDirection.y));
    }
    
    lastShotTime = millis();
  }
}

void spawnEnemy() {
  float x, y;
  int side = (int)random(4); // 0: top, 1: right, 2: bottom, 3: left
  
  switch(side) {
    case 0: // top
      x = random(width);
      y = -20;
      break;
    case 1: // right
      x = width + 20;
      y = random(height);
      break;
    case 2: // bottom
      x = random(width);
      y = height + 20;
      break;
    case 3: // left
      x = -20;
      y = random(height);
      break;
    default:
      x = random(width);
      y = -20;
  }
  
  int health = 1;
  if (currentRound >= 5) health = 2;
  if (currentRound >= 7) health = 3;
  
  float speed = enemySpeed * enemySpeedMultiplier;
  if (currentRound >= 7) speed *= 1.2;
  
  enemies.add(new Enemy(x, y, health, speed));
  enemiesAlive++;
}

void startRound() {
  roundInProgress = true;
  roundComplete = false;
  
  // Determine number of enemies based on round
  switch(currentRound) {
    case 1: enemiesToSpawn = 4; break;
    case 2: enemiesToSpawn = 6; break;
    case 3: enemiesToSpawn = 8; break;
    case 4: enemiesToSpawn = 10; break;
    case 5: enemiesToSpawn = 12; break;
    case 6: enemiesToSpawn = 13; break;
    case 7: enemiesToSpawn = 14; break;
    case 8: enemiesToSpawn = 15; break;
    default: enemiesToSpawn = 15 + (currentRound - 8) * 2;
  }
  
  enemiesAlive = 0;
  bullets.clear();
}

void roundComplete() {
  roundInProgress = false;
  roundComplete = true;
  roundText = "Rodada " + currentRound + " Concluída!";
  roundTextDisplayTime = millis();
  
  currentRound++;
  
  if (currentRound > 8) { // All rounds completed
    gameState = YOU_WIN;
  } else {
    // Prepare upgrade options
    prepareUpgradeOptions();
    gameState = UPGRADE_SCREEN;
  }
}

void prepareUpgradeOptions() {
  // Clear previous selections
  selectedUpgradeIndex = -1;
  upgradeSelected = false;
  
  // Get available upgrades that haven't reached their max
  ArrayList<Upgrade> possibleUpgrades = new ArrayList<Upgrade>();
  for (Upgrade u : availableUpgrades) {
    if (u.timesSelected < u.maxTimes) {
      possibleUpgrades.add(u);
    }
  }
  
  // If no upgrades left, skip to next round
  if (possibleUpgrades.size() == 0) {
    countingDown = true;
    nextRoundTime = millis();
    countdown = 3;
    gameState = GAME_SCREEN;
    return;
  }
  
  // Select 3 random upgrades (or less if not enough available)
  for (int i = 0; i < min(3, possibleUpgrades.size()); i++) {
    int randomIndex = (int)random(possibleUpgrades.size());
    currentUpgradeOptions[i] = possibleUpgrades.get(randomIndex);
    possibleUpgrades.remove(randomIndex);
  }
  
  // Fill remaining slots with null if not enough upgrades
  for (int i = possibleUpgrades.size(); i < 3; i++) {
    currentUpgradeOptions[i] = null;
  }
}

void applyUpgrade(Upgrade upgrade) {
  switch(upgrade.name) {
    case "VIDA EXTRA":
      playerMaxLives++;
      playerLives++;
      break;
    case "DANO EXTRA":
      playerDamage++;
      break;
    case "VEL. DE ATAQUE":
      fireRate = max(0.1, fireRate - 0.1); // Minimum 0.1 seconds between shots
      break;
    case "LIBERDADE X":
      freedomX = true;
      break;
    case "LIBERDADE Y":
      freedomY = true;
      break;
    case "ATAQUE DUPLO":
      doubleShot = true;
      break;
    case "VELOCIDADE":
      playerSpeed += 0.5;
      break;
    case "DISPARO MAIOR":
      bulletSize += 2;
      break;
  }
  
  upgrade.timesSelected++;
  
  // Start countdown to next round
  countingDown = true;
  nextRoundTime = millis();
  countdown = 3;
  gameState = GAME_SCREEN;
}

void resetGame() {
  // Reset player
  playerLives = 3;
  playerMaxLives = 3;
  playerDamage = 1;
  fireRate = 0.5;
  playerPos.set(width/2, height/2);
  freedomX = false;
  freedomY = false;
  playerSpeed = 2;
  doubleShot = false;
  bulletSize = 5;
  
  // Reset game state
  currentRound = 1;
  bullets.clear();
  enemies.clear();
  
  // Reset upgrades
  for (Upgrade u : availableUpgrades) {
    u.timesSelected = 0;
  }
  selectedUpgrades.clear();
  
  // Go back to start screen
  gameState = START_SCREEN;
}

class Bullet {
  float x, y;
  float vx, vy;
  float speed = 8;
  
  Bullet(float x, float y, float vx, float vy) {
    this.x = x;
    this.y = y;
    this.vx = vx * speed;
    this.vy = vy * speed;
  }
  
  void update() {
    x += vx;
    y += vy;
  }
  
  void display() {
    fill(255, 255, 0);
    ellipse(x, y, bulletSize, bulletSize);
  }
  
  boolean isOffScreen() {
    return x < 0 || x > width || y < 0 || y > height;
  }
}

class Enemy {
  float x, y;
  int health;
  float speed;
  float size = 20;
  
  Enemy(float x, float y, int health, float speed) {
    this.x = x;
    this.y = y;
    this.health = health;
    this.speed = speed;
  }
  
  void update() {
    PVector direction = new PVector(playerPos.x - x, playerPos.y - y).normalize();
    x += direction.x * speed;
    y += direction.y * speed;
  }
  
  void display() {
    fill(255, 165, 0); // Orange
    ellipse(x, y, size, size);
    
    // Display health if more than 1
    if (health > 1) {
      fill(255);
      textAlign(CENTER, CENTER);
      textSize(12);
      text(health, x, y);
    }
  }
  
  boolean collidesWithPlayer() {
    float distance = dist(x, y, playerPos.x, playerPos.y);
    return distance < (size/2 + 15); // Player radius is 15
  }
  
  boolean collidesWith(Bullet b) {
    float distance = dist(x, y, b.x, b.y);
    return distance < (size/2 + bulletSize/2);
  }
  
  void takeDamage(int damage) {
    health -= damage;
  }
}

class Upgrade {
  String name;
  String description;
  int maxTimes;
  int timesSelected = 0;
  
  Upgrade(String name, String description, int maxTimes) {
    this.name = name;
    this.description = description;
    this.maxTimes = maxTimes;
  }
}
